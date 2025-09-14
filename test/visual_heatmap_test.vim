" Visual heatmap test - demonstrates actual output
source autoload/logstroker/heatmap.vim

" Realistic test data
let test_stats = {
  \ 'total_keystrokes': 500,
  \ 'key_frequencies': {
    \ 'j': {'count': 85, 'percentage': 17.0, 'context': 'movement'},
    \ 'k': {'count': 72, 'percentage': 14.4, 'context': 'movement'},
    \ 'h': {'count': 58, 'percentage': 11.6, 'context': 'movement'},
    \ 'l': {'count': 45, 'percentage': 9.0, 'context': 'movement'},
    \ 'w': {'count': 35, 'percentage': 7.0, 'context': 'movement'},
    \ 'i': {'count': 40, 'percentage': 8.0, 'context': 'mode_switch'},
    \ 'a': {'count': 32, 'percentage': 6.4, 'context': 'mode_switch'},
    \ '<Esc>': {'count': 25, 'percentage': 5.0, 'context': 'mode_switch'},
    \ 'x': {'count': 15, 'percentage': 3.0, 'context': 'editing'},
    \ 'd': {'count': 12, 'percentage': 2.4, 'context': 'editing'}
  \ }
\ }

echo "=== KEYBOARD HEATMAP TEST ==="
let heatmap = logstroker#heatmap#generate_keyboard_heatmap(test_stats)
let rendered = logstroker#heatmap#render_heatmap(heatmap)
for line in rendered
  echo line
endfor

echo ""
echo "=== COMMAND FREQUENCY TEST ==="
let command_heatmap = logstroker#heatmap#generate_command_heatmap(test_stats.key_frequencies)
let command_rendered = logstroker#heatmap#render_heatmap(command_heatmap)
for line in command_rendered
  echo line
endfor

echo ""
echo "=== SESSION COMPARISON TEST ==="
" Create session data (different pattern)
let session_stats = {
  \ 'total_keystrokes': 50,
  \ 'key_frequencies': {
    \ 'j': {'count': 20, 'percentage': 40.0, 'context': 'movement'},
    \ 'w': {'count': 15, 'percentage': 30.0, 'context': 'movement'},
    \ 'i': {'count': 10, 'percentage': 20.0, 'context': 'mode_switch'},
    \ '<Esc>': {'count': 5, 'percentage': 10.0, 'context': 'mode_switch'}
  \ }
\ }

let comparison = logstroker#heatmap#generate_comparison_heatmap(session_stats, test_stats)
let comparison_rendered = logstroker#heatmap#render_comparison_heatmap(comparison)
for line in comparison_rendered[0:15]  " Show first 15 lines
  echo line
endfor
echo "... (truncated for brevity)"