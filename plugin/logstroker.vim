" logstroker.vim - Vim keystroke analysis plugin
" Author: Logstroker Plugin
" Version: 1.0

" Prevent loading twice
if exists('g:loaded_logstroker') || &cp
  finish
endif
let g:loaded_logstroker = 1

" Save user's cpoptions and set to vim defaults
let s:save_cpo = &cpo
set cpo&vim

" Load configuration defaults (will be loaded on first use)

" Define user commands
command! LogstrokerToggle call logstroker#window#toggle()
command! LogstrokerAnalyze call logstroker#analyze()
command! -nargs=1 LogstrokerSetKeylog call logstroker#config#set_keylog_path(<q-args>)

" Real-time monitoring commands
command! LogstrokerStartMonitoring call logstroker#start_monitoring()
command! LogstrokerStopMonitoring call logstroker#stop_monitoring()
command! LogstrokerMonitoringStatus call logstroker#monitoring_status()
command! LogstrokerToggleAutoRefresh call logstroker#config#toggle_auto_refresh()
command! -nargs=1 LogstrokerSetRefreshInterval call logstroker#config#set_auto_refresh(<args>)
command! LogstrokerClearCache call logstroker#parser#clear_cache()
command! LogstrokerShowStats call logstroker#window#show_stats()

" Set up default key mapping if not already defined
if !hasmapto('<Plug>LogstrokerToggle')
  " Load config to get toggle key, with fallback
  try
    call logstroker#config#load_defaults()
    execute 'nmap ' . g:logstroker_toggle_key . ' <Plug>LogstrokerToggle'
  catch
    " Fallback to F2 if config loading fails
    nmap <F2> <Plug>LogstrokerToggle
  endtry
endif

" Define plugin mappings
nnoremap <silent> <Plug>LogstrokerToggle :LogstrokerToggle<CR>

" Restore user's cpoptions
let &cpo = s:save_cpo
unlet s:save_cpo
