" autoload/logstroker/window.vim - Window management and UI
" Author: Logstroker Plugin
" Version: 1.0

" Global variables for window state
let s:logstroker_bufnr = -1
let s:logstroker_winnr = -1
let s:window_open = 0

" Toggle the analysis window
function! logstroker#window#toggle()
  if s:window_open && bufexists(s:logstroker_bufnr)
    call s:close_window()
  else
    call s:open_window()
  endif
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
  call setbufvar(l:bufnr, '&modifiable', 0)
  call setbufvar(l:bufnr, '&readonly', 1)
  call setbufvar(l:bufnr, '&wrap', 0)
  call setbufvar(l:bufnr, '&filetype', 'logstroker')
  
  " Store buffer number for tracking
  let s:logstroker_bufnr = l:bufnr
  
  return l:bufnr
endfunction

" Update window content with analysis data
function! logstroker#window#update_content(...)
  if !s:window_open || !bufexists(s:logstroker_bufnr)
    return
  endif
  
  " Get analysis data (use dummy data if not provided)
  let l:analysis = a:0 > 0 ? a:1 : s:get_dummy_analysis()
  let l:heatmap = a:0 > 1 ? a:2 : s:get_dummy_heatmap()
  
  " Switch to the analysis buffer
  let l:current_win = winnr()
  execute bufwinnr(s:logstroker_bufnr) . 'wincmd w'
  
  " Make buffer modifiable for updates
  setlocal modifiable
  
  " Clear existing content
  silent %delete _
  
  " Generate and insert content
  let l:content = s:generate_content(l:analysis, l:heatmap)
  call setline(1, l:content)
  
  " Make buffer read-only again
  setlocal nomodifiable
  
  " Return to original window
  execute l:current_win . 'wincmd w'
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
    " Get fresh analysis data
    let l:keylog_path = logstroker#config#get_keylog_path()
    let l:keystrokes = logstroker#parser#get_session_data()
    let l:analysis = logstroker#anal#analyze_patterns(l:keystrokes)
    let l:heatmap = logstroker#heatmap#generate_keyboard_heatmap(l:analysis)
    
    " Update content
    call logstroker#window#update_content(l:analysis, l:heatmap)
    
    echo "Logstroker: Analysis refreshed"
  catch
    echo "Logstroker: Error refreshing analysis - " . v:exception
  endtry
endfunction

" Show help information
function! logstroker#window#show_help()
  echo "Logstroker Help: q/ESC=close, r=refresh, ?=help, Enter=select"
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
    
    " Update content with initial data
    call logstroker#window#update_content()
    
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
  
  let s:window_open = 0
  let s:logstroker_winnr = -1
  echo "Logstroker: Analysis window closed"
endfunction

" Reset window state (for testing and cleanup)
function! logstroker#window#reset_state()
  let s:logstroker_bufnr = -1
  let s:logstroker_winnr = -1
  let s:window_open = 0
endfunction

" Generate window content from analysis data
function! s:generate_content(analysis, heatmap)
  let l:content = []
  
  " Header section
  call add(l:content, '┌─ Logstroker Analysis ─────────────────────────┐')
  
  " Session info
  let l:session_time = get(a:analysis, 'session_time', '0 min')
  let l:total_time = get(a:analysis, 'total_time', '0 hours')
  call add(l:content, '│ Session: ' . l:session_time . ' | Total: ' . l:total_time . repeat(' ', 47 - len('│ Session: ' . l:session_time . ' | Total: ' . l:total_time)) . '│')
  
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
  let l:commands = get(a:analysis, 'top_commands', [])
  for i in range(min([len(l:commands), 5]))
    let l:cmd = l:commands[i]
    let l:name = get(l:cmd, 'key', '?')
    let l:count = get(l:cmd, 'count', 0)
    let l:percent = get(l:cmd, 'percent', 0)
    let l:bar = repeat('█', l:percent / 5)
    let l:line = printf('%s: %s %d (%d%%)', l:name, l:bar, l:count, l:percent)
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
      let l:text = l:text[:37] . '...'
    endif
    call add(l:content, '│ • ' . l:text . repeat(' ', 43 - len(l:text)) . '│')
  endfor
  
  " Add empty lines if fewer than 5 suggestions
  for i in range(len(l:suggestions), 4)
    call add(l:content, '│                                               │')
  endfor
  
  " Footer
  call add(l:content, '└───────────────────────────────────────────────┘')
  call add(l:content, '')
  call add(l:content, 'Press ? for help, r to refresh, q to close')
  
  return l:content
endfunction

" Format heatmap data for display
function! s:format_heatmap(heatmap)
  let l:lines = []
  
  " Simple ASCII keyboard layout
  call add(l:lines, '[q][w][e][r][t][y][u][i][o][p]')
  call add(l:lines, ' [a][s][d][f][g][h][j][k][l]')
  call add(l:lines, '  [z][x][c][v][b][n][m]')
  
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