" autoload/logstroker/config.vim - Configuration management
" Author: Logstroker Plugin
" Version: 1.0

" Load default configuration values
function! logstroker#config#load_defaults()
  " Default keylog directory path
  if !exists('g:logstroker_keylog_path')
    let g:logstroker_keylog_path = expand('~/.vim/vimlog')
  endif
  
  " Default toggle key mapping
  if !exists('g:logstroker_toggle_key')
    let g:logstroker_toggle_key = '<F2>'
  endif
  
  " Default analysis window width
  if !exists('g:logstroker_window_width')
    let g:logstroker_window_width = 50
  endif
  
  " Default auto-refresh interval (seconds)
  if !exists('g:logstroker_auto_refresh')
    let g:logstroker_auto_refresh = 5
  endif
  
  " Default minimum threshold for pattern detection
  if !exists('g:logstroker_min_threshold')
    let g:logstroker_min_threshold = 3
  endif
  
  " Default suggestion categories (all enabled by default)
  if !exists('g:logstroker_enable_ergonomic_suggestions')
    let g:logstroker_enable_ergonomic_suggestions = 1
  endif
  
  if !exists('g:logstroker_enable_efficiency_suggestions')
    let g:logstroker_enable_efficiency_suggestions = 1
  endif
  
  if !exists('g:logstroker_enable_navigation_suggestions')
    let g:logstroker_enable_navigation_suggestions = 1
  endif
endfunction

" Get the configured keylog directory path
function! logstroker#config#get_keylog_path()
  return g:logstroker_keylog_path
endfunction

" Set the keylog directory path
function! logstroker#config#set_keylog_path(path)
  let g:logstroker_keylog_path = expand(a:path)
  echo "Logstroker: Keylog directory set to " . g:logstroker_keylog_path
endfunction

" Get the number of recent files to analyze for quick suggestions
function! logstroker#config#get_recent_files_limit()
  if !exists('g:logstroker_recent_files_limit')
    let g:logstroker_recent_files_limit = 5
  endif
  return g:logstroker_recent_files_limit
endfunction

" Get window width setting
function! logstroker#config#get_window_width()
  return g:logstroker_window_width
endfunction

" Get auto-refresh interval
function! logstroker#config#get_auto_refresh()
  return g:logstroker_auto_refresh
endfunction

" Get minimum threshold for pattern detection
function! logstroker#config#get_min_threshold()
  return g:logstroker_min_threshold
endfunction

" Check if suggestion category is enabled
function! logstroker#config#is_ergonomic_enabled()
  return g:logstroker_enable_ergonomic_suggestions
endfunction

function! logstroker#config#is_efficiency_enabled()
  return g:logstroker_enable_efficiency_suggestions
endfunction

function! logstroker#config#is_navigation_enabled()
  return g:logstroker_enable_navigation_suggestions
endfunction

" Validate configuration settings
function! logstroker#config#validate()
  let l:errors = []
  
  " Validate window width
  if g:logstroker_window_width < 30 || g:logstroker_window_width > 120
    call add(l:errors, "Window width must be between 30 and 120")
    let g:logstroker_window_width = 50
  endif
  
  " Validate auto-refresh interval
  if g:logstroker_auto_refresh < 1
    call add(l:errors, "Auto-refresh interval must be at least 1 second")
    let g:logstroker_auto_refresh = 5
  endif
  
  " Validate minimum threshold
  if g:logstroker_min_threshold < 1
    call add(l:errors, "Minimum threshold must be at least 1")
    let g:logstroker_min_threshold = 3
  endif
  
  " Report any validation errors
  if len(l:errors) > 0
    echohl WarningMsg
    echo "Logstroker configuration warnings:"
    for error in l:errors
      echo "  - " . error
    endfor
    echohl None
  endif
  
  return len(l:errors) == 0
endfunction