" autoload/logstroker.vim - Main logstroker functionality
" Author: Logstroker Plugin
" Version: 1.0

" Main analysis function
function! logstroker#analyze()
  " Get keylog file path from configuration
  let l:keylog_path = logstroker#config#get_keylog_path()
  
  " Check if keylog directory exists
  if !isdirectory(l:keylog_path)
    echohl ErrorMsg
    echo "Logstroker: Keylog directory not found at " . l:keylog_path
    echo "Use :LogstrokerSetKeylog <path> to set the correct path"
    echohl None
    return
  endif
  
  " Get session data using pagination for efficiency
  let l:session_data = logstroker#parser#get_session_data_paginated(1)
  
  if !l:session_data.success
    echohl ErrorMsg
    echo "Logstroker: " . l:session_data.error
    echohl None
    return
  endif
  
  " Analyze patterns
  let l:analysis = logstroker#anal#analyze_patterns(l:session_data.data)
  
  " Generate heatmap
  let l:heatmap = logstroker#heatmap#generate_keyboard_heatmap(l:analysis)
  
  " Add real-time stats
  let l:realtime_stats = logstroker#parser#get_realtime_stats()
  if l:realtime_stats.success
    let l:analysis.realtime_stats = l:realtime_stats
  endif
  
  " Update window with results
  call logstroker#window#update_content(l:analysis, l:heatmap)
endfunction

" Start real-time monitoring
function! logstroker#start_monitoring()
  call logstroker#parser#start_monitoring()
  echo "Logstroker: Real-time monitoring started"
endfunction

" Stop real-time monitoring
function! logstroker#stop_monitoring()
  call logstroker#parser#stop_monitoring()
  echo "Logstroker: Real-time monitoring stopped"
endfunction

" Get monitoring status
function! logstroker#monitoring_status()
  let l:cache_stats = logstroker#parser#get_cache_stats()
  let l:realtime_stats = logstroker#parser#get_realtime_stats()
  
  echo "=== Logstroker Monitoring Status ==="
  echo "Monitoring: " . (l:cache_stats.monitoring_active ? "Active" : "Inactive")
  echo "Window auto-refresh: " . (logstroker#window#is_auto_refresh_enabled() ? "Enabled" : "Disabled")
  echo "Global auto-refresh: " . (logstroker#config#is_auto_refresh_enabled() ? "Enabled" : "Disabled")
  echo "Refresh interval: " . logstroker#config#get_auto_refresh() . " seconds"
  
  if l:realtime_stats.success
    echo "Current file: " . fnamemodify(l:realtime_stats.file, ':t')
    echo "Estimated keystrokes: " . l:realtime_stats.estimated_keystrokes
  endif
endfunction

" Public API function to get plugin version
function! logstroker#version()
  return "1.0"
endfunction