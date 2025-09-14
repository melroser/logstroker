" autoload/logstroker.vim - Main logstroker functionality
" Author: Logstroker Plugin
" Version: 1.0

" Main analysis function
function! logstroker#analyze()
  " Get keylog file path from configuration
  let l:keylog_path = logstroker#config#get_keylog_path()
  
  " Check if keylog file exists
  if !filereadable(l:keylog_path)
    echohl ErrorMsg
    echo "Logstroker: Keylog file not found at " . l:keylog_path
    echo "Use :LogstrokerSetKeylog <path> to set the correct path"
    echohl None
    return
  endif
  
  " Parse keylog data
  let l:raw_data = logstroker#parser#read_keylog(l:keylog_path)
  let l:keystrokes = logstroker#parser#parse_keystrokes(l:raw_data)
  
  " Analyze patterns
  let l:analysis = logstroker#anal#analyze_patterns(l:keystrokes)
  
  " Generate heatmap
  let l:heatmap = logstroker#heatmap#generate_keyboard_heatmap(l:analysis)
  
  " Update window with results
  call logstroker#window#update_content(l:analysis, l:heatmap)
endfunction

" Public API function to get plugin version
function! logstroker#version()
  return "1.0"
endfunction