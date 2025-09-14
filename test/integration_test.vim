" test/integration_test.vim - Integration test for window module
" Author: Logstroker Plugin
" Version: 1.0

" Add the autoload directory to the runtime path
let s:plugin_root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
execute 'set runtimepath+=' . s:plugin_root

" Source all required modules
source autoload/logstroker/config.vim
source autoload/logstroker/window.vim

" Simple integration test
function! TestWindowIntegration()
  echo "Testing window integration..."
  
  " Load configuration
  call logstroker#config#load_defaults()
  
  " Test window toggle
  echo "Opening window..."
  call logstroker#window#toggle()
  
  if logstroker#window#is_open()
    echo "✓ Window opened successfully"
    
    " Test refresh (will fail gracefully without other modules)
    echo "Testing refresh..."
    call logstroker#window#refresh()
    
    " Close window
    echo "Closing window..."
    call logstroker#window#toggle()
    
    if !logstroker#window#is_open()
      echo "✓ Window closed successfully"
      echo "✓ Integration test passed!"
    else
      echo "✗ Failed to close window"
    endif
  else
    echo "✗ Failed to open window"
  endif
  
  " Cleanup
  call logstroker#window#reset_state()
endfunction

" Run the test
call TestWindowIntegration()