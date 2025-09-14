" autoload/logstroker/window.vim - Window management and UI
" Author: Logstroker Plugin
" Version: 1.0

" Global variables for window state
let s:logstroker_bufnr = -1
let s:logstroker_winnr = -1
let s:window_open = 0
let s:last_refresh_time = 0
let s:auto_refresh_enabled = 0
let s:auto_refresh_timer = -1

" Toggle the analysis window
function! logstroker#window#toggle()
  if s:window_open && bufexists(s:logstroker_bufnr)
    call s:close_window()
  else
    call s:open_window()
  endif
endfunction

" Enable/disable auto-refresh for the window
function! logstroker#window#toggle_auto_refresh()
  let s:auto_refresh_enabled = !s:auto_refresh_enabled
  
  if s:auto_refresh_enabled && s:window_open
    call s:start_auto_refresh()
    echo "Logstroker: Auto-refresh enabled (every " . logstroker#config#get_auto_refresh() . "s)"
  else
    call s:stop_auto_refresh()
    echo "Logstroker: Auto-refresh disabled"
  endif
  
  return s:auto_refresh_enabled
endfunction

" Start auto-refresh timer
function! s:start_auto_refresh()
  if s:auto_refresh_timer != -1
    call timer_stop(s:auto_refresh_timer)
  endif
  
  let l:interval = logstroker#config#get_auto_refresh() * 1000  " Convert to milliseconds
  let s:auto_refresh_timer = timer_start(l:interval, 's:auto_refresh_callback', {'repeat': -1})
endfunction

" Stop auto-refresh timer
function! s:stop_auto_refresh()
  if s:auto_refresh_timer != -1
    call timer_stop(s:auto_refresh_timer)
    let s:auto_refresh_timer = -1
  endif
endfunction

" Auto-refresh callback
function! s:auto_refresh_callback(timer_id)
  if s:window_open && s:auto_refresh_enabled
    call logstroker#window#refresh()
  endif
endfunction

" Check if auto-refresh is enabled for window
function! logstroker#window#is_auto_refresh_enabled()
  return s:auto_refresh_enabled
endfunction

" Create and configure the analysis buffer
function! logstroker#window#create_buffer()
  " Create a new buffer for the analysis window
  let l:bufnr = bufnr('__Logstroker_Analysis__', 1)
  
  " Configure buffer settings using setbufvar to avoid switching buffers
  call setbufvar(l:bufnr, '&buftype', 'nofile')
  call setbufvar(l:bufnr, '&bufhidden', 'hide')
  call setbufvar(l:bufnr, '&swapfile', 0)
  call setbufvar(l:bufnr, '&buflisted', 0)
  call setbufvar(l:bufnr, '&modifiable', 1)
  call setbufvar(l:bufnr, '&readonly', 0)
  call setbufvar(l:bufnr, '&wrap', 0)
  call setbufvar(l:bufnr, '&filetype', 'logstroker')
  
  " Store buffer number for tracking
  let s:logstroker_bufnr = l:bufnr
  
  return l:bufnr
endfunction

" Update window content with analysis data
function! logstroker#window#update_content(...)
  if !bufexists(s:logstroker_bufnr)
    return
  endif
  
  " This function is deprecated - content is now generated directly in refresh
  return
endfunction

" Set up window-specific key mappings
function! logstroker#window#setup_keymaps()
  if !bufexists(s:logstroker_bufnr)
    return
  endif
  
  " Set up buffer-local key mappings
  execute 'nnoremap <buffer> <silent> q :call logstroker#window#toggle()<CR>'
  execute 'nnoremap <buffer> <silent> <ESC> :call logstroker#window#toggle()<CR>'
  execute 'nnoremap <buffer> <silent> r :call logstroker#window#refresh()<CR>'
  execute 'nnoremap <buffer> <silent> a :call logstroker#window#toggle_auto_refresh()<CR>'
  execute 'nnoremap <buffer> <silent> c :call logstroker#window#clear_cache()<CR>'

  execute 'nnoremap <buffer> <silent> ? :call logstroker#window#show_help()<CR>'
  execute 'nnoremap <buffer> <silent> <CR> :call logstroker#window#select_item()<CR>'
  execute 'nnoremap <buffer> <silent> j j'
  execute 'nnoremap <buffer> <silent> k k'
  execute 'nnoremap <buffer> <silent> gg gg'
  execute 'nnoremap <buffer> <silent> G G'
endfunction

" Refresh window content
function! logstroker#window#refresh()
  if !s:window_open
    return
  endif
  
  try
    " Debug: show what path we're looking for
    let l:keylog_path = logstroker#config#get_keylog_path()
    " Try to get the most recent keylog file directly
    let l:log_files = glob(l:keylog_path . '/vimlog*.txt', 0, 1)
    
    if len(l:log_files) > 0
      " Sort by modification time (newest first)
      let l:file_times = []
      for file in l:log_files
        call add(l:file_times, [getftime(file), file])
      endfor
      call sort(l:file_times, {a, b -> b[0] - a[0]})
      
      " Get the second most recent file (previous session)
      if len(l:file_times) > 1
        let l:recent_file = l:file_times[1][1]
      else
        let l:recent_file = l:file_times[0][1]
      endif
      
      " Read and parse the file
      let l:raw_data = logstroker#parser#read_keylog(l:recent_file)
      if l:raw_data.success
        let l:keystrokes = logstroker#parser#parse_keystrokes(l:raw_data.data)
        
        if len(l:keystrokes) > 0
          " Create simple analysis data to avoid dictionary errors
          let l:simple_analysis = {
            \ 'total_keystrokes': len(l:keystrokes),
            \ 'key_frequencies': {},
            \ 'suggestions': [{'text': 'Analysis completed with ' . len(l:keystrokes) . ' keystrokes'}]
          \ }
          
          " Count key frequencies manually
          for keystroke in l:keystrokes
            let l:key = keystroke.key
            if has_key(l:simple_analysis.key_frequencies, l:key)
              let l:simple_analysis.key_frequencies[l:key] += 1
            else
              let l:simple_analysis.key_frequencies[l:key] = 1
            endif
          endfor
          
          " Create content with keyboard heatmap
          let l:simple_content = [
            \ '┌─ Logstroker Analysis ─────────────────────────┐',
            \ '│ Loaded ' . len(l:keystrokes) . ' keystrokes from previous session │',
            \ '├───────────────────────────────────────────────┤',
            \ '│ KEYBOARD HEATMAP:                             │'
          \ ]
          
          " Generate simple keyboard heatmap
          let l:heatmap_lines = s:generate_simple_heatmap(l:simple_analysis.key_frequencies)
          for line in l:heatmap_lines
            call add(l:simple_content, '│ ' . line . repeat(' ', 45 - len(line)) . '│')
          endfor
          
          call add(l:simple_content, '│                                               │')
          call add(l:simple_content, '│ TOP KEYS:                                     │')
          
          " Add top 5 readable keys (filter out weird codes)
          let l:readable_keys = []
          for key in keys(l:simple_analysis.key_frequencies)
            " Only show readable keys (letters, numbers, common symbols)
            if key =~# '^[a-zA-Z0-9.,;:!?<>(){}[\]"'"'"'`~@#$%^&*+=/_-]$' || key ==# ' '
              call add(l:readable_keys, key)
            endif
          endfor
          
          let l:sorted_keys = sort(l:readable_keys, {a, b -> l:simple_analysis.key_frequencies[b] - l:simple_analysis.key_frequencies[a]})
          for i in range(min([5, len(l:sorted_keys)]))
            let l:key = l:sorted_keys[i]
            let l:count = l:simple_analysis.key_frequencies[l:key]
            let l:display_key = l:key ==# ' ' ? '<Space>' : l:key
            let l:line = '│ ' . l:display_key . ': ' . l:count . ' times'
            call add(l:simple_content, l:line . repeat(' ', 47 - len(l:line)) . '│')
          endfor
          
          call add(l:simple_content, '└───────────────────────────────────────────────┘')
          call add(l:simple_content, 'Press a=auto-refresh, r=refresh, q=close')
          
          " Update buffer directly
          setlocal modifiable
          setlocal noreadonly
          silent %delete _
          call setline(1, l:simple_content)
          setlocal nomodifiable
          
          " Silently loaded keystrokes
        else
          call logstroker#window#update_content()
          echo "Logstroker: No keystrokes found in file"
        endif
      else
        call logstroker#window#update_content()
        echo "Logstroker: Error reading file - " . l:raw_data.error
      endif
    else
      call logstroker#window#update_content()
      echo "Logstroker: No vimlog*.txt files found in " . l:keylog_path
    endif
  catch
    call logstroker#window#update_content()
    echo "Logstroker: Error - " . v:exception
  endtry
endfunction

" Clear cache and refresh
function! logstroker#window#clear_cache()
  call logstroker#parser#clear_cache()
  call logstroker#window#refresh()
  echo "Logstroker: Cache cleared and refreshed"
endfunction

" Show simple statistics
function! logstroker#window#show_stats()
  let l:keylog_path = logstroker#config#get_keylog_path()
  let l:log_files = glob(l:keylog_path . '/vimlog*.txt', 0, 1)
  
  echo "=== Logstroker Statistics ==="
  echo "Keylog directory: " . l:keylog_path
  echo "Total log files: " . len(l:log_files)
  echo "Auto-refresh: Disabled (simplified version)"
  echo "Real-time monitoring: Disabled (simplified version)"
  echo ""
  echo "Press r to refresh analysis with latest data"
endfunction

" Show help information
function! logstroker#window#show_help()
  echo "Logstroker Help:"
  echo "  q/ESC=close, r=refresh, a=toggle auto-refresh"
  echo "  c=clear cache, s=show stats, ?=help, Enter=select"
endfunction

" Handle item selection (placeholder for future functionality)
function! logstroker#window#select_item()
  let l:line = getline('.')
  if l:line =~ '^  •'
    echo "Selected suggestion: " . substitute(l:line, '^  • ', '', '')
  endif
endfunction

" Check if window is currently open
function! logstroker#window#is_open()
  return s:window_open
endfunction

" Get window buffer number
function! logstroker#window#get_bufnr()
  return s:logstroker_bufnr
endfunction

" Private function to open the analysis window
function! s:open_window()
  try
    " Create buffer if it doesn't exist
    if !bufexists(s:logstroker_bufnr)
      let s:logstroker_bufnr = logstroker#window#create_buffer()
    endif
    
    " Get window width from configuration
    let l:width = logstroker#config#get_window_width()
    
    " Open vertical split window
    execute 'vertical ' . l:width . 'split'
    execute 'buffer ' . s:logstroker_bufnr
    
    " Store window number
    let s:logstroker_winnr = winnr()
    let s:window_open = 1
    
    " Set window-specific display options
    setlocal nonumber
    setlocal norelativenumber
    setlocal cursorline
    
    " Set up key mappings
    call logstroker#window#setup_keymaps()
    
    " Set window title
    execute 'file __Logstroker_Analysis__'
    
    " Load real data immediately when window opens
    try
      call logstroker#window#refresh()
    catch
      " If refresh fails, show error message
      setlocal modifiable
      call setline(1, ['Error loading data: ' . v:exception, 'Press r to try again'])
      setlocal nomodifiable
    endtry

    
    " Auto-refresh disabled by default
    " if logstroker#config#is_auto_refresh_enabled()
    "   let s:auto_refresh_enabled = 1
    "   call logstroker#parser#start_monitoring()
    " endif
    
    " Position cursor at top
    normal! gg
    
    echo "Logstroker: Analysis window opened (press ? for help)"
    
  catch
    echohl ErrorMsg
    echo "Logstroker: Failed to open analysis window - " . v:exception
    echohl None
    let s:window_open = 0
  endtry
endfunction

" Private function to close the analysis window
function! s:close_window()
  if s:window_open && bufexists(s:logstroker_bufnr)
    let l:winnr = bufwinnr(s:logstroker_bufnr)
    if l:winnr != -1
      execute l:winnr . 'wincmd w'
      close
    endif
  endif
  
  " Stop monitoring when window closes
  call logstroker#parser#stop_monitoring()
  let s:auto_refresh_enabled = 0
  
  let s:window_open = 0
  let s:logstroker_winnr = -1
  echo "Logstroker: Analysis window closed"
endfunction

" Reset window state (for testing and cleanup)
function! logstroker#window#reset_state()
  call logstroker#parser#stop_monitoring()
  let s:logstroker_bufnr = -1
  let s:logstroker_winnr = -1
  let s:window_open = 0
  let s:last_refresh_time = 0
  let s:auto_refresh_enabled = 0
endfunction

" Generate window content from analysis data
function! s:generate_content(analysis, heatmap)
  let l:content = []
  
  " Header section
  call add(l:content, '┌─ Logstroker Analysis ─────────────────────────┐')
  
  " Session info with real-time status
  let l:statistics = get(a:analysis, 'statistics', {})
  let l:session_summary = get(l:statistics, 'session_summary', {})
  let l:session_time = get(l:session_summary, 'duration', '0 min')
  let l:total_keystrokes = get(a:analysis, 'total_keystrokes', 0)
  if type(l:total_keystrokes) != type(0)
    let l:total_keystrokes = 0
  endif
  let l:last_updated = get(a:analysis, 'last_updated', '')
  let l:auto_status = s:auto_refresh_enabled ? ' [AUTO]' : ''
  
  let l:session_line = '│ Session: ' . l:session_time . ' | Keys: ' . l:total_keystrokes . l:auto_status
  call add(l:content, l:session_line . repeat(' ', 47 - len(l:session_line)) . '│')
  
  if !empty(l:last_updated)
    let l:update_line = '│ Last updated: ' . l:last_updated
    call add(l:content, l:update_line . repeat(' ', 47 - len(l:update_line)) . '│')
  endif
  
  call add(l:content, '├───────────────────────────────────────────────┤')
  
  " Keyboard heatmap section
  call add(l:content, '│ KEYBOARD HEATMAP                              │')
  let l:heatmap_lines = s:format_heatmap(a:heatmap)
  for line in l:heatmap_lines
    call add(l:content, '│ ' . line . repeat(' ', 45 - len(line)) . '│')
  endfor
  
  call add(l:content, '│                                               │')
  
  " Top commands section
  call add(l:content, '│ TOP COMMANDS (Current Session)                │')
  let l:key_frequencies = get(a:analysis, 'key_frequencies', {})
  let l:total_keys = get(a:analysis, 'total_keystrokes', 1)
  if type(l:total_keys) != type(0)
    let l:total_keys = 1
  endif
  
  " Convert key frequencies to sorted list
  let l:commands = []
  for key in keys(l:key_frequencies)
    let l:count = l:key_frequencies[key]
    let l:percent = l:total_keys > 0 ? (l:count * 100) / l:total_keys : 0
    call add(l:commands, {'key': key, 'count': l:count, 'percent': l:percent})
  endfor
  
  " Sort by count (descending)
  call sort(l:commands, {a, b -> b.count - a.count})
  
  for i in range(min([len(l:commands), 5]))
    let l:cmd = l:commands[i]
    let l:name = l:cmd.key
    let l:count = l:cmd.count
    let l:percent = l:cmd.percent
    let l:bar = repeat('█', min([l:percent / 2, 20]))  " Scale bar appropriately
    let l:line = printf('%s: %s %d (%d%%)', l:name, l:bar, l:count, l:percent)
    if len(l:line) > 45
      let l:line = l:line[:min([41, len(l:line)-1])] . '...'
    endif
    call add(l:content, '│ ' . l:line . repeat(' ', 45 - len(l:line)) . '│')
  endfor
  
  " Add empty lines if fewer than 5 commands
  for i in range(len(l:commands), 4)
    call add(l:content, '│                                               │')
  endfor
  
  call add(l:content, '│                                               │')
  
  " Suggestions section
  call add(l:content, '│ SUGGESTIONS                                   │')
  let l:suggestions = get(a:analysis, 'suggestions', [])
  for i in range(min([len(l:suggestions), 5]))
    let l:suggestion = l:suggestions[i]
    let l:text = get(l:suggestion, 'text', 'No suggestions available')
    " Truncate long suggestions
    if len(l:text) > 41
      let l:text = l:text[:min([37, len(l:text)-1])] . '...'
    endif
    call add(l:content, '│ • ' . l:text . repeat(' ', 43 - len(l:text)) . '│')
  endfor
  
  " Add empty lines if fewer than 5 suggestions
  for i in range(len(l:suggestions), 4)
    call add(l:content, '│                                               │')
  endfor
  
  " Real-time stats section if available
  let l:realtime_stats = get(a:analysis, 'realtime_stats', {})
  if !empty(l:realtime_stats) && l:realtime_stats.success
    call add(l:content, '│                                               │')
    call add(l:content, '│ REAL-TIME STATUS                              │')
    let l:file_name = fnamemodify(l:realtime_stats.file, ':t')
    let l:file_line = '│ File: ' . l:file_name
    call add(l:content, l:file_line . repeat(' ', 47 - len(l:file_line)) . '│')
    
    let l:size_kb = l:realtime_stats.file_size / 1024
    let l:size_line = '│ Size: ' . l:size_kb . ' KB, Lines: ' . l:realtime_stats.total_lines
    call add(l:content, l:size_line . repeat(' ', 47 - len(l:size_line)) . '│')
    
    let l:monitoring_status = l:realtime_stats.monitoring_active ? 'Active' : 'Inactive'
    let l:monitor_line = '│ Monitoring: ' . l:monitoring_status
    call add(l:content, l:monitor_line . repeat(' ', 47 - len(l:monitor_line)) . '│')
  endif
  
  " Footer
  call add(l:content, '└───────────────────────────────────────────────┘')
  call add(l:content, '')
  call add(l:content, 'Press ? for help, a=auto-refresh, r=refresh, q=close')
  
  return l:content
endfunction

" Generate simple heatmap showing key usage intensity
function! s:generate_simple_heatmap(key_frequencies)
  let l:lines = []
  
  " Define keyboard layout
  let l:rows = [
    \ ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    \ ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    \ ['z', 'x', 'c', 'v', 'b', 'n', 'm']
  \ ]
  
  " Find max frequency for scaling (only readable keys)
  let l:max_freq = 0
  for [key, freq] in items(a:key_frequencies)
    if key =~# '^[a-zA-Z0-9]$' && freq > l:max_freq
      let l:max_freq = freq
    endif
  endfor
  
  " Generate heatmap rows
  for row in l:rows
    let l:line = ''
    for key in row
      let l:freq = get(a:key_frequencies, key, 0)
      if l:max_freq > 0
        let l:intensity = (l:freq * 3) / l:max_freq  " Scale 0-3
      else
        let l:intensity = 0
      endif
      
      " Choose character based on intensity
      if l:intensity >= 3
        let l:char = '█'  " Heavy usage
      elseif l:intensity >= 2
        let l:char = '▓'  " Medium usage
      elseif l:intensity >= 1
        let l:char = '▒'  " Light usage
      else
        let l:char = '░'  " Very light/no usage
      endif
      
      let l:line .= '[' . l:char . ']'
    endfor
    call add(l:lines, l:line)
  endfor
  
  return l:lines
endfunction

" Get dummy analysis data for testing
function! s:get_dummy_analysis()
  return {
    \ 'session_time': '45 min',
    \ 'total_time': '12.3 hours',
    \ 'top_commands': [
    \   {'key': 'j', 'count': 45, 'percent': 23},
    \   {'key': 'k', 'count': 38, 'percent': 19},
    \   {'key': 'h', 'count': 28, 'percent': 14},
    \   {'key': 'l', 'count': 22, 'percent': 11},
    \   {'key': 'i', 'count': 18, 'percent': 9}
    \ ],
    \ 'suggestions': [
    \   {'text': "Use 'w' instead of repeated 'l'"},
    \   {'text': "Consider ':' instead of ESC then ':'"},
    \   {'text': "Try 'A' instead of '$' then 'a'"},
    \   {'text': "Use 'o' instead of 'A' then Enter"},
    \   {'text': "Consider 'ci(' for changing in parentheses"}
    \ ]
    \ }
endfunction

" Get dummy heatmap data for testing
function! s:get_dummy_heatmap()
  return {
    \ 'keyboard_layout': {},
    \ 'intensities': {}
    \ }
endfunction