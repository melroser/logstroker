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

" Load configuration defaults
call logstroker#config#load_defaults()

" Define user commands
command! LogstrokerToggle call logstroker#window#toggle()
command! LogstrokerAnalyze call logstroker#analyze()
command! -nargs=1 LogstrokerSetKeylog call logstroker#config#set_keylog_path(<q-args>)

" Set up default key mapping if not already defined
if !hasmapto('<Plug>LogstrokerToggle')
  execute 'nmap ' . g:logstroker_toggle_key . ' <Plug>LogstrokerToggle'
endif

" Define plugin mappings
nnoremap <silent> <Plug>LogstrokerToggle :LogstrokerToggle<CR>

" Restore user's cpoptions
let &cpo = s:save_cpo
unlet s:save_cpo
