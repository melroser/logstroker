" autoload/logstroker/test.vim - Unit tests for parser module
" Author: Logstroker Plugin
" Version: 1.0

" Test framework setup
let s:test_results = []
let s:test_count = 0
let s:pass_count = 0

" Test helper functions
function! s:assert_equal(expected, actual, message)
  let s:test_count += 1
  if a:expected ==# a:actual
    let s:pass_count += 1
    call add(s:test_results, 'PASS: ' . a:message)
  else
    call add(s:test_results, 'FAIL: ' . a:message . ' (expected: ' . string(a:expected) . ', got: ' . string(a:actual) . ')')
  endif
endfunction

function! s:assert_true(condition, message)
  let s:test_count += 1
  if a:condition
    let s:pass_count += 1
    call add(s:test_results, 'PASS: ' . a:message)
  else
    call add(s:test_results, 'FAIL: ' . a:message . ' (condition was false)')
  endif
endfunction

function! s:assert_false(condition, message)
  let s:test_count += 1
  if !a:condition
    let s:pass_count += 1
    call add(s:test_results, 'PASS: ' . a:message)
  else
    call add(s:test_results, 'FAIL: ' . a:message . ' (condition was true)')
  endif
endfunction

" Create test keylog file
function! s:create_test_keylog(filename, content)
  call writefile(a:content, a:filename)
endfunction

" Clean up test files
function! s:cleanup_test_files()
  for file in glob('/tmp/test_keylog_*', 0, 1)
    call delete(file)
  endfor
endfunction

" Test: read_keylog with valid file
function! s:test_read_keylog_valid_file()
  let l:test_file = '/tmp/test_keylog_valid.log'
  let l:test_content = ['hjkl', 'iHello', ':wq']
  call s:create_test_keylog(l:test_file, l:test_content)
  
  let l:result = logstroker#parser#read_keylog(l:test_file)
  
  call s:assert_true(l:result.success, 'read_keylog should succeed with valid file')
  call s:assert_equal(3, len(l:result.data), 'read_keylog should return correct number of lines')
  call s:assert_equal('hjkl', l:result.data[0], 'read_keylog should return correct first line')
  call s:assert_equal('', l:result.error, 'read_keylog should have no error with valid file')
  
  call delete(l:test_file)
endfunction

" Test: read_keylog with missing file
function! s:test_read_keylog_missing_file()
  let l:result = logstroker#parser#read_keylog('/tmp/nonexistent_keylog.log')
  
  call s:assert_false(l:result.success, 'read_keylog should fail with missing file')
  call s:assert_equal(0, len(l:result.data), 'read_keylog should return empty data for missing file')
  call s:assert_true(len(l:result.error) > 0, 'read_keylog should return error message for missing file')
endfunction

" Test: parse_keystrokes with simple input
function! s:test_parse_keystrokes_simple()
  let l:raw_data = ['hjkl', 'x']
  let l:result = logstroker#parser#parse_keystrokes(l:raw_data)
  
  call s:assert_equal(5, len(l:result), 'parse_keystrokes should return 5 keystrokes for hjklx')
  call s:assert_equal('h', l:result[0].key, 'First keystroke should be h')
  call s:assert_equal('j', l:result[1].key, 'Second keystroke should be j')
  call s:assert_equal('k', l:result[2].key, 'Third keystroke should be k')
  call s:assert_equal('l', l:result[3].key, 'Fourth keystroke should be l')
  call s:assert_equal('x', l:result[4].key, 'Fifth keystroke should be x')
endfunction

" Test: parse_keystrokes with empty input
function! s:test_parse_keystrokes_empty()
  let l:result = logstroker#parser#parse_keystrokes([])
  
  call s:assert_equal(0, len(l:result), 'parse_keystrokes should return empty array for empty input')
endfunction

" Test: keystroke event structure
function! s:test_keystroke_event_structure()
  let l:raw_data = ['h']
  let l:result = logstroker#parser#parse_keystrokes(l:raw_data)
  
  call s:assert_equal(1, len(l:result), 'Should have one keystroke')
  
  let l:keystroke = l:result[0]
  call s:assert_true(has_key(l:keystroke, 'key'), 'Keystroke should have key field')
  call s:assert_true(has_key(l:keystroke, 'timestamp'), 'Keystroke should have timestamp field')
  call s:assert_true(has_key(l:keystroke, 'mode'), 'Keystroke should have mode field')
  call s:assert_true(has_key(l:keystroke, 'sequence'), 'Keystroke should have sequence field')
  call s:assert_true(has_key(l:keystroke, 'session_id'), 'Keystroke should have session_id field')
  call s:assert_true(has_key(l:keystroke, 'context'), 'Keystroke should have context field')
  
  call s:assert_equal('h', l:keystroke.key, 'Key should be h')
  call s:assert_equal('movement', l:keystroke.context, 'h should be classified as movement')
  call s:assert_equal('normal', l:keystroke.mode, 'h should be in normal mode')
endfunction

" Test: context detection
function! s:test_context_detection()
  let l:raw_data = ['h', 'j', 'k', 'l', 'x', 'i', ':', 'w']
  let l:result = logstroker#parser#parse_keystrokes(l:raw_data)
  
  call s:assert_equal('movement', l:result[0].context, 'h should be movement')
  call s:assert_equal('movement', l:result[1].context, 'j should be movement')
  call s:assert_equal('movement', l:result[2].context, 'k should be movement')
  call s:assert_equal('movement', l:result[3].context, 'l should be movement')
  call s:assert_equal('editing', l:result[4].context, 'x should be editing')
  call s:assert_equal('mode_switch', l:result[5].context, 'i should be mode_switch')
  call s:assert_equal('command', l:result[6].context, ': should be command')
  call s:assert_equal('movement', l:result[7].context, 'w should be movement')
endfunction

" Test: log directory functionality
function! s:test_log_directory_functionality()
  " Create test log directory
  let l:test_dir = '/tmp/test_vimlog'
  call mkdir(l:test_dir, 'p')
  
  " Create test log files with timestamp pattern
  let l:test_files = [
    \ l:test_dir . '/vimlog-20240101-120000.txt',
    \ l:test_dir . '/vimlog-20240101-130000.txt',
    \ l:test_dir . '/vimlog-20240101-140000.txt'
  \ ]
  
  call s:create_test_keylog(l:test_files[0], ['hjkl'])
  call s:create_test_keylog(l:test_files[1], ['iHello'])
  call s:create_test_keylog(l:test_files[2], ['x'])
  
  " Mock the config to use our test directory
  let l:original_path = exists('g:logstroker_keylog_path') ? g:logstroker_keylog_path : ''
  let g:logstroker_keylog_path = l:test_dir
  
  " Test directory stats
  let l:stats = logstroker#parser#get_log_directory_stats()
  call s:assert_true(l:stats.success, 'get_log_directory_stats should succeed')
  call s:assert_equal(3, l:stats.total_files, 'Should find 3 log files')
  
  " Test listing log files
  let l:file_list = logstroker#parser#list_log_files()
  call s:assert_equal(3, len(l:file_list), 'Should list 3 log files')
  
  " Test previous session data
  let l:result = logstroker#parser#get_previous_session_data()
  call s:assert_true(l:result.success, 'get_previous_session_data should succeed')
  call s:assert_true(len(l:result.data) > 0, 'Should return keystroke data')
  
  " Restore original config
  if !empty(l:original_path)
    let g:logstroker_keylog_path = l:original_path
  endif
  
  " Clean up
  for file in l:test_files
    call delete(file)
  endfor
  call delete(l:test_dir, 'd')
endfunction



" Run all tests
function! logstroker#test#run_parser_tests()
  echo "Running parser module tests..."
  
  " Reset test counters
  let s:test_results = []
  let s:test_count = 0
  let s:pass_count = 0
  
  " Run tests
  call s:test_read_keylog_valid_file()
  call s:test_read_keylog_missing_file()
  call s:test_parse_keystrokes_simple()
  call s:test_parse_keystrokes_empty()
  call s:test_keystroke_event_structure()
  call s:test_context_detection()
  call s:test_log_directory_functionality()
  
  " Clean up
  call s:cleanup_test_files()
  
  " Display results
  echo "\n=== Parser Test Results ==="
  for result in s:test_results
    echo result
  endfor
  
  echo "\n=== Summary ==="
  echo "Tests run: " . s:test_count
  echo "Passed: " . s:pass_count
  echo "Failed: " . (s:test_count - s:pass_count)
  
  if s:pass_count == s:test_count
    echo "All tests passed!"
    return 1
  else
    echo "Some tests failed!"
    return 0
  endif
endfunction

" Note: Analysis tests have been moved to test/test_logstroker.vim
" This file now only contains parser tests for backward compatibility

" Run all tests (parser only - analysis tests are in test/ directory)
function! logstroker#test#run_all_tests()
  echo "Running parser tests..."
  echo "Note: Analysis tests are now in test/test_logstroker.vim"
  
  let l:parser_result = logstroker#test#run_parser_tests()
  
  echo "\n" . repeat("=", 50)
  echo "=== TEST SUMMARY ==="
  echo "Parser tests: " . (l:parser_result ? "PASSED" : "FAILED")
  echo "For analysis tests, run: vim -c 'source test/test_logstroker.vim' -c ':q'"
  
  return l:parser_result
endfunction