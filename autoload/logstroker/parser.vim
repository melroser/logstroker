" autoload/logstroker/parser.vim - Keylog file parsing
" Author: Logstroker Plugin
" Version: 1.0

" Global variables for session tracking
let s:current_session_id = ''
let s:session_start_time = 0
let s:file_cache = {}
let s:file_timestamps = {}
let s:monitoring_active = 0

" Initialize session tracking
function! s:init_session()
  if empty(s:current_session_id)
    let s:current_session_id = localtime() . '_' . getpid()
    let s:session_start_time = localtime()
  endif
endfunction

" Get current session ID
function! logstroker#parser#get_session_id()
  call s:init_session()
  return s:current_session_id
endfunction

" Read keylog file and return raw data with error handling
function! logstroker#parser#read_keylog(filepath)
  let l:result = {
    \ 'success': 0,
    \ 'data': [],
    \ 'error': ''
  \ }
  
  " Expand path to handle ~ and environment variables
  let l:expanded_path = expand(a:filepath)
  
  " Check if file exists
  if !filereadable(l:expanded_path)
    let l:result.error = 'Keylog file not found: ' . l:expanded_path
    return l:result
  endif
  
  " Try to read the file
  try
    let l:lines = readfile(l:expanded_path)
    let l:result.success = 1
    let l:result.data = l:lines
  catch /^Vim\%((\a\+)\)\=:E/
    let l:result.error = 'Failed to read keylog file: ' . v:exception
  endtry
  
  return l:result
endfunction

" Parse raw keylog data into structured keystroke events
function! logstroker#parser#parse_keystrokes(raw_data)
  let l:keystrokes = []
  let l:line_number = 0
  
  call s:init_session()
  
  for line in a:raw_data
    let l:line_number += 1
    
    " Skip empty lines and comments
    if empty(line) || line =~# '^#'
      continue
    endif
    
    " Parse keystroke line - vim keylog format is typically just the keys
    " Each character or key sequence represents a keystroke
    let l:parsed_keys = s:parse_keystroke_line(line, l:line_number)
    call extend(l:keystrokes, l:parsed_keys)
  endfor
  
  return l:keystrokes
endfunction

" Parse a single line of keylog data into individual keystroke events
function! s:parse_keystroke_line(line, line_number)
  let l:keystrokes = []
  let l:i = 0
  let l:len = len(a:line)
  let l:sequence = 0
  
  while l:i < l:len
    let l:keystroke = s:extract_next_keystroke(a:line, l:i)
    
    if !empty(l:keystroke.key)
      let l:event = {
        \ 'key': l:keystroke.key,
        \ 'timestamp': s:generate_timestamp(a:line_number, l:sequence),
        \ 'mode': s:detect_vim_mode(l:keystroke.key, l:keystrokes),
        \ 'sequence': l:sequence,
        \ 'session_id': s:current_session_id,
        \ 'line_number': a:line_number,
        \ 'context': s:determine_context(l:keystroke.key)
      \ }
      
      call add(l:keystrokes, l:event)
      let l:sequence += 1
    endif
    
    let l:i = l:keystroke.next_pos
  endwhile
  
  return l:keystrokes
endfunction

" Extract the next keystroke from a line, handling special key sequences
function! s:extract_next_keystroke(line, start_pos)
  let l:result = {'key': '', 'next_pos': a:start_pos + 1}
  
  if a:start_pos >= len(a:line)
    return l:result
  endif
  
  let l:char = a:line[a:start_pos]
  
  " Handle escape sequences and special keys
  if l:char ==# "\<Esc>"
    let l:result.key = '<Esc>'
  elseif l:char ==# "\<CR>"
    let l:result.key = '<CR>'
  elseif l:char ==# "\<Tab>"
    let l:result.key = '<Tab>'
  elseif l:char ==# "\<BS>"
    let l:result.key = '<BS>'
  elseif l:char ==# "\<Del>"
    let l:result.key = '<Del>'
  elseif l:char ==# "\<Space>"
    let l:result.key = '<Space>'
  elseif l:char ==# "\<Up>"
    let l:result.key = '<Up>'
  elseif l:char ==# "\<Down>"
    let l:result.key = '<Down>'
  elseif l:char ==# "\<Left>"
    let l:result.key = '<Left>'
  elseif l:char ==# "\<Right>"
    let l:result.key = '<Right>'
  elseif l:char ==# "\<F1>"
    let l:result.key = '<F1>'
  elseif l:char ==# "\<F2>"
    let l:result.key = '<F2>'
  elseif l:char ==# "\<F3>"
    let l:result.key = '<F3>'
  elseif l:char ==# "\<F4>"
    let l:result.key = '<F4>'
  elseif l:char ==# "\<F5>"
    let l:result.key = '<F5>'
  elseif l:char ==# "\<F6>"
    let l:result.key = '<F6>'
  elseif l:char ==# "\<F7>"
    let l:result.key = '<F7>'
  elseif l:char ==# "\<F8>"
    let l:result.key = '<F8>'
  elseif l:char ==# "\<F9>"
    let l:result.key = '<F9>'
  elseif l:char ==# "\<F10>"
    let l:result.key = '<F10>'
  elseif l:char ==# "\<F11>"
    let l:result.key = '<F11>'
  elseif l:char ==# "\<F12>"
    let l:result.key = '<F12>'
  else
    " Regular character
    let l:result.key = l:char
  endif
  
  return l:result
endfunction

" Generate timestamp for keystroke (approximated based on line and sequence)
function! s:generate_timestamp(line_number, sequence)
  " Since vim keylog doesn't include timestamps, we approximate
  " Assume each line represents roughly 1 second of activity
  let l:estimated_time = s:session_start_time + a:line_number + (a:sequence * 0.1)
  return strftime('%Y-%m-%d %H:%M:%S', float2nr(l:estimated_time))
endfunction

" Detect vim mode based on keystroke context
function! s:detect_vim_mode(key, previous_keystrokes)
  " Simple mode detection based on key patterns
  if a:key ==# 'i' || a:key ==# 'a' || a:key ==# 'o' || a:key ==# 'O' || a:key ==# 'A' || a:key ==# 'I'
    return 'insert'
  elseif a:key ==# 'v' || a:key ==# 'V'
    return 'visual'
  elseif a:key ==# ':'
    return 'command'
  elseif a:key ==# '<Esc>'
    return 'normal'
  else
    " Try to infer from previous keystrokes
    if len(a:previous_keystrokes) > 0
      let l:last_mode = a:previous_keystrokes[-1].mode
      " If we're in insert mode and haven't seen escape, stay in insert
      if l:last_mode ==# 'insert' && a:key !=# '<Esc>'
        return 'insert'
      elseif l:last_mode ==# 'visual' && a:key !=# '<Esc>'
        return 'visual'
      elseif l:last_mode ==# 'command' && a:key !=# '<CR>' && a:key !=# '<Esc>'
        return 'command'
      endif
    endif
    return 'normal'
  endif
endfunction

" Determine keystroke context (movement, editing, navigation, etc.)
function! s:determine_context(key)
  " Movement keys
  if a:key =~# '^[hjklwbeWBE0$^]$'
    return 'movement'
  " Arrow keys
  elseif a:key =~# '^<\(Up\|Down\|Left\|Right\)>$'
    return 'movement'
  " Editing keys
  elseif a:key =~# '^[xXdDcCsSyYpP]$'
    return 'editing'
  " Mode switching
  elseif a:key =~# '^[iIaAoO]$' || a:key ==# '<Esc>'
    return 'mode_switch'
  " Search and navigation
  elseif a:key =~# '^[/?nNfFtT]$'
    return 'navigation'
  " Command mode
  elseif a:key ==# ':'
    return 'command'
  else
    return 'other'
  endif
endfunction

" Find log files in directory, sorted by modification time (newest first)
function! s:find_log_files(log_dir)
  let l:expanded_dir = expand(a:log_dir)
  
  if !isdirectory(l:expanded_dir)
    return []
  endif
  
  " Find all vimlog files matching the pattern
  let l:pattern = l:expanded_dir . '/vimlog-*.txt'
  let l:files = glob(l:pattern, 0, 1)
  
  " Sort by modification time (newest first)
  let l:file_times = []
  for file in l:files
    call add(l:file_times, [getftime(file), file])
  endfor
  
  call sort(l:file_times, {a, b -> b[0] - a[0]})
  
  return map(l:file_times, 'v:val[1]')
endfunction

" Get the most recent log file (previous session)
function! s:get_most_recent_log()
  let l:log_dir = logstroker#config#get_keylog_path()
  let l:log_files = s:find_log_files(l:log_dir)
  
  if len(l:log_files) == 0
    return ''
  endif
  
  return l:log_files[0]
endfunction

" Get keystroke data from the most recent log file (previous session)
function! logstroker#parser#get_previous_session_data()
  let l:recent_log = s:get_most_recent_log()
  
  if empty(l:recent_log)
    return {'success': 0, 'error': 'No log files found', 'data': []}
  endif
  
  let l:read_result = logstroker#parser#read_keylog(l:recent_log)
  
  if !l:read_result.success
    return {'success': 0, 'error': l:read_result.error, 'data': []}
  endif
  
  let l:keystrokes = logstroker#parser#parse_keystrokes(l:read_result.data)
  
  return {'success': 1, 'data': l:keystrokes, 'error': '', 'file': l:recent_log}
endfunction

" Get keystroke data for current session only (if logging to current file)
function! logstroker#parser#get_session_data()
  " For current session, we'd need to track the current log file
  " This is a placeholder - in practice, current session data would come
  " from the active vim session's log file
  return logstroker#parser#get_previous_session_data()
endfunction

" Get all historical keystroke data from all log files (memory intensive)
function! logstroker#parser#get_all_historical_data()
  let l:log_dir = logstroker#config#get_keylog_path()
  let l:log_files = s:find_log_files(l:log_dir)
  
  if len(l:log_files) == 0
    return {'success': 0, 'error': 'No log files found', 'data': []}
  endif
  
  let l:all_keystrokes = []
  let l:processed_files = []
  let l:errors = []
  
  for log_file in l:log_files
    let l:read_result = logstroker#parser#read_keylog(log_file)
    
    if l:read_result.success
      let l:keystrokes = logstroker#parser#parse_keystrokes(l:read_result.data)
      " Add file metadata to each keystroke
      for keystroke in l:keystrokes
        let keystroke.log_file = log_file
      endfor
      call extend(l:all_keystrokes, l:keystrokes)
      call add(l:processed_files, log_file)
    else
      call add(l:errors, 'Failed to read ' . log_file . ': ' . l:read_result.error)
    endif
  endfor
  
  return {
    \ 'success': 1,
    \ 'data': l:all_keystrokes,
    \ 'files_processed': l:processed_files,
    \ 'errors': l:errors,
    \ 'total_files': len(l:log_files)
  \ }
endfunction

" Get summary data from recent log files (lighter weight than full analysis)
function! logstroker#parser#get_recent_summary(max_files)
  let l:log_dir = logstroker#config#get_keylog_path()
  let l:log_files = s:find_log_files(l:log_dir)
  
  if len(l:log_files) == 0
    return {'success': 0, 'error': 'No log files found', 'data': []}
  endif
  
  " Limit to most recent files
  let l:files_to_process = l:log_files[0:min([a:max_files - 1, len(l:log_files) - 1])]
  let l:summary_data = []
  
  for log_file in l:files_to_process
    let l:read_result = logstroker#parser#read_keylog(log_file)
    
    if l:read_result.success
      let l:keystrokes = logstroker#parser#parse_keystrokes(l:read_result.data)
      let l:file_summary = {
        \ 'file': log_file,
        \ 'keystroke_count': len(l:keystrokes),
        \ 'timestamp': getftime(log_file),
        \ 'sample_keystrokes': l:keystrokes[0:min([99, len(l:keystrokes) - 1])]
      \ }
      call add(l:summary_data, l:file_summary)
    endif
  endfor
  
  return {'success': 1, 'data': l:summary_data, 'files_processed': len(l:files_to_process)}
endfunction

" Get all keystroke data (for backward compatibility)
function! logstroker#parser#get_all_data()
  return logstroker#parser#get_all_historical_data()
endfunction

" Validate keylog file format
function! logstroker#parser#validate_keylog(filepath)
  let l:read_result = logstroker#parser#read_keylog(a:filepath)
  
  if !l:read_result.success
    return {'valid': 0, 'error': l:read_result.error}
  endif
  
  " Check if file has reasonable content
  if len(l:read_result.data) == 0
    return {'valid': 0, 'error': 'Keylog file is empty'}
  endif
  
  " Try to parse a few lines to validate format
  let l:sample_lines = l:read_result.data[0:min([4, len(l:read_result.data)-1])]
  let l:parsed = logstroker#parser#parse_keystrokes(l:sample_lines)
  
  if len(l:parsed) == 0
    return {'valid': 0, 'error': 'No valid keystrokes found in file'}
  endif
  
  return {'valid': 1, 'error': ''}
endfunction

" List available log files with metadata
function! logstroker#parser#list_log_files()
  let l:log_dir = logstroker#config#get_keylog_path()
  let l:log_files = s:find_log_files(l:log_dir)
  
  let l:file_info = []
  for log_file in l:log_files
    let l:file_stat = {
      \ 'path': log_file,
      \ 'name': fnamemodify(log_file, ':t'),
      \ 'size': getfsize(log_file),
      \ 'modified': strftime('%Y-%m-%d %H:%M:%S', getftime(log_file)),
      \ 'timestamp': getftime(log_file)
    \ }
    call add(l:file_info, l:file_stat)
  endfor
  
  return l:file_info
endfunction

" Get quick stats from log directory without full parsing
function! logstroker#parser#get_log_directory_stats()
  let l:log_dir = logstroker#config#get_keylog_path()
  let l:log_files = s:find_log_files(l:log_dir)
  
  if len(l:log_files) == 0
    return {'success': 0, 'error': 'No log files found in ' . l:log_dir}
  endif
  
  let l:total_size = 0
  let l:oldest_file = ''
  let l:newest_file = ''
  let l:oldest_time = 0
  let l:newest_time = 0
  
  for log_file in l:log_files
    let l:size = getfsize(log_file)
    let l:time = getftime(log_file)
    
    let l:total_size += l:size
    
    if empty(l:oldest_file) || l:time < l:oldest_time
      let l:oldest_file = log_file
      let l:oldest_time = l:time
    endif
    
    if empty(l:newest_file) || l:time > l:newest_time
      let l:newest_file = log_file
      let l:newest_time = l:time
    endif
  endfor
  
  return {
    \ 'success': 1,
    \ 'directory': l:log_dir,
    \ 'total_files': len(l:log_files),
    \ 'total_size_bytes': l:total_size,
    \ 'oldest_file': l:oldest_file,
    \ 'newest_file': l:newest_file,
    \ 'date_range': strftime('%Y-%m-%d', l:oldest_time) . ' to ' . strftime('%Y-%m-%d', l:newest_time)
  \ }
endfunction

" Check if file has been modified since last check
function! logstroker#parser#file_changed(filepath)
  let l:current_time = getftime(a:filepath)
  let l:cached_time = get(s:file_timestamps, a:filepath, 0)
  
  if l:current_time > l:cached_time
    let s:file_timestamps[a:filepath] = l:current_time
    return 1
  endif
  
  return 0
endfunction

" Read keylog with pagination for large files
function! logstroker#parser#read_keylog_paginated(filepath, start_line, page_size)
  let l:result = {
    \ 'success': 0,
    \ 'data': [],
    \ 'error': '',
    \ 'total_lines': 0,
    \ 'has_more': 0
  \ }
  
  let l:expanded_path = expand(a:filepath)
  
  if !filereadable(l:expanded_path)
    let l:result.error = 'Keylog file not found: ' . l:expanded_path
    return l:result
  endif
  
  " Check file size
  let l:file_size = getfsize(l:expanded_path)
  let l:max_size = logstroker#config#get_max_file_size()
  
  try
    let l:all_lines = readfile(l:expanded_path)
    let l:result.total_lines = len(l:all_lines)
    
    " Calculate pagination
    let l:start_idx = max([0, a:start_line - 1])
    let l:end_idx = min([len(l:all_lines) - 1, l:start_idx + a:page_size - 1])
    
    let l:result.data = l:all_lines[l:start_idx:l:end_idx]
    let l:result.has_more = l:end_idx < len(l:all_lines) - 1
    let l:result.success = 1
    
  catch /^Vim\%((\a\+)\)\=:E/
    let l:result.error = 'Failed to read keylog file: ' . v:exception
  endtry
  
  return l:result
endfunction

" Get incremental updates from keylog file
function! logstroker#parser#get_incremental_data(filepath)
  let l:cache_key = a:filepath
  
  " Check if file has changed
  if !logstroker#parser#file_changed(a:filepath)
    return {'success': 1, 'data': [], 'incremental': 1, 'message': 'No changes detected'}
  endif
  
  " Get cached line count
  let l:cached_lines = get(s:file_cache, l:cache_key . '_lines', 0)
  
  " Read new lines only
  let l:page_size = logstroker#config#get_page_size()
  let l:read_result = logstroker#parser#read_keylog_paginated(a:filepath, l:cached_lines + 1, l:page_size)
  
  if !l:read_result.success
    return l:read_result
  endif
  
  " Update cache
  let s:file_cache[l:cache_key . '_lines'] = l:read_result.total_lines
  
  " Parse new keystrokes
  let l:new_keystrokes = logstroker#parser#parse_keystrokes(l:read_result.data)
  
  return {
    \ 'success': 1,
    \ 'data': l:new_keystrokes,
    \ 'incremental': 1,
    \ 'new_lines': len(l:read_result.data),
    \ 'total_lines': l:read_result.total_lines
  \ }
endfunction

" Start monitoring keylog files for changes
function! logstroker#parser#start_monitoring()
  if s:monitoring_active
    return
  endif
  
  let s:monitoring_active = 1
  call s:schedule_monitoring_check()
endfunction

" Stop monitoring keylog files
function! logstroker#parser#stop_monitoring()
  let s:monitoring_active = 0
endfunction

" Check if monitoring is active
function! logstroker#parser#is_monitoring()
  return s:monitoring_active
endfunction

" Private function to schedule monitoring checks
function! s:schedule_monitoring_check()
  if !s:monitoring_active || !logstroker#config#is_auto_refresh_enabled()
    return
  endif
  
  let l:interval = logstroker#config#get_auto_refresh() * 1000  " Convert to milliseconds
  call timer_start(l:interval, 's:monitoring_callback')
endfunction

" Monitoring callback function
function! s:monitoring_callback(timer_id)
  if !s:monitoring_active
    return
  endif
  
  try
    " Check if analysis window is open
    if logstroker#window#is_open()
      " Get keylog path
      let l:keylog_path = logstroker#config#get_keylog_path()
      
      " Check for changes in recent files
      let l:log_files = s:find_log_files(l:keylog_path)
      let l:has_changes = 0
      
      for log_file in l:log_files[0:2]  " Check top 3 most recent files
        if logstroker#parser#file_changed(log_file)
          let l:has_changes = 1
          break
        endif
      endfor
      
      " Refresh window if changes detected
      if l:has_changes
        call logstroker#window#refresh()
      endif
    endif
  catch
    " Silently handle errors to avoid disrupting user workflow
  endtry
  
  " Schedule next check
  call s:schedule_monitoring_check()
endfunction

" Clear file cache
function! logstroker#parser#clear_cache()
  let s:file_cache = {}
  let s:file_timestamps = {}
endfunction

" Get cache statistics
function! logstroker#parser#get_cache_stats()
  return {
    \ 'cached_files': len(s:file_timestamps),
    \ 'cache_entries': len(s:file_cache),
    \ 'monitoring_active': s:monitoring_active
  \ }
endfunction

" Efficient session data tracking with pagination
function! logstroker#parser#get_session_data_paginated(page_number)
  let l:page_size = logstroker#config#get_page_size()
  let l:start_line = (a:page_number - 1) * l:page_size + 1
  
  let l:recent_log = s:get_most_recent_log()
  
  if empty(l:recent_log)
    return {'success': 0, 'error': 'No log files found', 'data': []}
  endif
  
  let l:read_result = logstroker#parser#read_keylog_paginated(l:recent_log, l:start_line, l:page_size)
  
  if !l:read_result.success
    return l:read_result
  endif
  
  let l:keystrokes = logstroker#parser#parse_keystrokes(l:read_result.data)
  
  return {
    \ 'success': 1,
    \ 'data': l:keystrokes,
    \ 'page': a:page_number,
    \ 'page_size': l:page_size,
    \ 'total_lines': l:read_result.total_lines,
    \ 'has_more': l:read_result.has_more,
    \ 'file': l:recent_log
  \ }
endfunction

" Get real-time statistics without full file parsing
function! logstroker#parser#get_realtime_stats()
  let l:log_dir = logstroker#config#get_keylog_path()
  let l:log_files = s:find_log_files(l:log_dir)
  
  if len(l:log_files) == 0
    return {'success': 0, 'error': 'No log files found'}
  endif
  
  let l:recent_file = l:log_files[0]
  let l:file_size = getfsize(l:recent_file)
  let l:mod_time = getftime(l:recent_file)
  
  " Quick line count estimation
  let l:sample_result = logstroker#parser#read_keylog_paginated(l:recent_file, 1, 100)
  let l:estimated_keystrokes = 0
  
  if l:sample_result.success && len(l:sample_result.data) > 0
    let l:sample_keystrokes = logstroker#parser#parse_keystrokes(l:sample_result.data)
    let l:keystrokes_per_line = len(l:sample_keystrokes) / len(l:sample_result.data)
    let l:estimated_keystrokes = float2nr(l:keystrokes_per_line * l:sample_result.total_lines)
  endif
  
  return {
    \ 'success': 1,
    \ 'file': l:recent_file,
    \ 'file_size': l:file_size,
    \ 'last_modified': strftime('%Y-%m-%d %H:%M:%S', l:mod_time),
    \ 'estimated_keystrokes': l:estimated_keystrokes,
    \ 'total_lines': get(l:sample_result, 'total_lines', 0),
    \ 'monitoring_active': s:monitoring_active
  \ }
endfunction