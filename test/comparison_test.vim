" Test session vs historical comparison
source autoload/logstroker/heatmap.vim

" Session data - heavy j/k usage
let session_stats = {
  \ 'total_keystrokes': 100,
  \ 'key_frequencies': {
    \ 'j': {'count': 40, 'percentage': 40.0, 'context': 'movement'},
    \ 'k': {'count': 30, 'percentage': 30.0, 'context': 'movement'},
    \ 'h': {'count': 20, 'percentage': 20.0, 'context': 'movement'},
    \ 'l': {'count': 10, 'percentage': 10.0, 'context': 'movement'}
  \ }
\ }

" Historical data - more balanced usage
let historical_stats = {
  \ 'total_keystrokes': 1000,
  \ 'key_frequencies': {
    \ 'j': {'count': 150, 'percentage': 15.0, 'context': 'movement'},
    \ 'k': {'count': 120, 'percentage': 12.0, 'context': 'movement'},
    \ 'h': {'count': 100, 'percentage': 10.0, 'context': 'movement'},
    \ 'l': {'count': 80, 'percentage': 8.0, 'context': 'movement'},
    \ 'w': {'count': 200, 'percentage': 20.0, 'context': 'movement'},
    \ 'b': {'count': 150, 'percentage': 15.0, 'context': 'movement'},
    \ 'i': {'count': 100, 'percentage': 10.0, 'context': 'mode_switch'},
    \ 'a': {'count': 100, 'percentage': 10.0, 'context': 'mode_switch'}
  \ }
\ }

echo "Testing comparison heatmap generation..."
let comparison = logstroker#heatmap#generate_comparison_heatmap(session_stats, historical_stats)

echo "Session total: " . comparison.session_total
echo "Historical total: " . comparison.historical_total
echo "Differences found: " . len(comparison.differences)

if len(comparison.differences) > 0
  echo "Key differences detected:"
  for diff in comparison.differences
    echo "  " . diff.key . " " . diff.change . " (difference: " . diff.difference . ")"
  endfor
endif

echo "Comparison test completed successfully!"