" test/integration_realtime_test.vim - End-to-end integration test for real-time functionality
" Author: Logstroker Plugin
" Version: 1.0

" Load the plugin
source plugin/logstroker.vim

function! Test_EndToEndRealtimeIntegration()
  echo "=== End-to-End Real-time Integration Test ==="
  
  " Setup test environment
  let l:test_dir = tempname()
  call mkdir(l:test_dir, 'p')
  
  let l:test_log = l:test_dir . '/vimlog-001.txt'
  call writefile(['hjklhjklhjkl', 'iiiaaaooo', ':wq'], l:test_log)
  
  try
    " Configure plugin for test
    execute 'LogstrokerSetKeylog ' . l:test_dir
    
    " Test basic analysis
    LogstrokerAnalyze
    echo "✓ Basic analysis completed"
    
    " Test monitoring commands
    LogstrokerStartMonitoring
    echo "✓ Monitoring started"
    
    LogstrokerMonitoringStatus
    echo "✓ Monitoring status displayed"
    
    " Test auto-refresh toggle
    LogstrokerToggleAutoRefresh
    echo "✓ Auto-refresh toggled"
    
    " Test cache operations
    LogstrokerClearCache
    echo "✓ Cache cleared"
    
    " Test window operations
    LogstrokerToggle
    echo "✓ Analysis window opened"
    
    " Simulate file change
    sleep 1
    call writefile(['new keystrokes here'], l:test_log, 'a')
    
    " Test refresh
    call logstroker#window#refresh()
    echo "✓ Window refreshed with new data"
    
    " Test stats display
    LogstrokerShowStats
    echo "✓ Statistics displayed"
    
    " Close window
    LogstrokerToggle
    echo "✓ Analysis window closed"
    
    " Stop monitoring
    LogstrokerStopMonitoring
    echo "✓ Monitoring stopped"
    
    echo "=== End-to-End Integration Test Passed! ==="
    
  catch
    echo "❌ Integration test failed: " . v:exception
    echo "At: " . v:throwpoint
  finally
    " Cleanup
    call logstroker#parser#stop_monitoring()
    call logstroker#window#reset_state()
    call delete(l:test_dir, 'rf')
  endtry
endfunction

" Run the integration test
call Test_EndToEndRealtimeIntegration()