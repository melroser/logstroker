" autoload/logstroker/heatmap.vim - Heatmap visualization
" Author: Logstroker Plugin
" Version: 1.0

" Generate keyboard layout heatmap with intensity indicators
function! logstroker#heatmap#generate_keyboard_heatmap(stats)
  if empty(a:stats) || !has_key(a:stats, 'key_frequencies')
    return s:empty_heatmap()
  endif
  
  let l:heatmap = {
    \ 'keyboard_layout': s:create_keyboard_layout(a:stats.key_frequencies),
    \ 'intensity_map': s:calculate_intensity_map(a:stats.key_frequencies),
    \ 'color_mapping': s:generate_color_mapping(a:stats.key_frequencies),
    \ 'max_intensity': s:get_max_intensity(a:stats.key_frequencies),
    \ 'total_keystrokes': get(a:stats, 'total_keystrokes', 0)
  \ }
  
  return l:heatmap
endfunction

" Generate command frequency heatmap with bars and percentages
function! logstroker#heatmap#generate_command_heatmap(commands)
  if empty(a:commands)
    return s:empty_command_heatmap()
  endif
  
  " Sort commands by frequency
  let l:sorted_commands = sort(items(a:commands), 's:compare_command_frequency')
  let l:top_commands = l:sorted_commands[0:9]  " Top 10 commands
  
  let l:command_heatmap = {
    \ 'top_commands': l:top_commands,
    \ 'frequency_bars': s:generate_frequency_bars(l:top_commands),
    \ 'percentages': s:calculate_command_percentages(l:top_commands),
    \ 'total_commands': len(a:commands)
  \ }
  
  return l:command_heatmap
endfunction

" Render heatmap data to display format
function! logstroker#heatmap#render_heatmap(heatmap_data)
  if empty(a:heatmap_data)
    return ['No heatmap data available']
  endif
  
  let l:output = []
  
  " Render keyboard layout if available
  if has_key(a:heatmap_data, 'keyboard_layout')
    call extend(l:output, s:render_keyboard_layout(a:heatmap_data))
    call add(l:output, '')
  endif
  
  " Render command frequencies if available
  if has_key(a:heatmap_data, 'top_commands')
    call extend(l:output, s:render_command_frequencies(a:heatmap_data))
  endif
  
  return l:output
endfunction

" Generate session vs historical comparison heatmap
function! logstroker#heatmap#generate_comparison_heatmap(session_stats, historical_stats)
  let l:session_heatmap = logstroker#heatmap#generate_keyboard_heatmap(a:session_stats)
  let l:historical_heatmap = logstroker#heatmap#generate_keyboard_heatmap(a:historical_stats)
  
  let l:comparison = {
    \ 'session': l:session_heatmap,
    \ 'historical': l:historical_heatmap,
    \ 'differences': s:calculate_heatmap_differences(l:session_heatmap, l:historical_heatmap),
    \ 'session_total': get(a:session_stats, 'total_keystrokes', 0),
    \ 'historical_total': get(a:historical_stats, 'total_keystrokes', 0)
  \ }
  
  return l:comparison
endfunction

" Render comparison heatmap for display
function! logstroker#heatmap#render_comparison_heatmap(comparison_data)
  if empty(a:comparison_data)
    return ['No comparison data available']
  endif
  
  let l:output = []
  
  " Session header
  call add(l:output, '=== CURRENT SESSION ===')
  call add(l:output, 'Keystrokes: ' . a:comparison_data.session_total)
  call extend(l:output, logstroker#heatmap#render_heatmap(a:comparison_data.session))
  call add(l:output, '')
  
  " Historical header
  call add(l:output, '=== HISTORICAL DATA ===')
  call add(l:output, 'Keystrokes: ' . a:comparison_data.historical_total)
  call extend(l:output, logstroker#heatmap#render_heatmap(a:comparison_data.historical))
  call add(l:output, '')
  
  " Differences
  if has_key(a:comparison_data, 'differences') && !empty(a:comparison_data.differences)
    call add(l:output, '=== KEY DIFFERENCES ===')
    call extend(l:output, s:render_differences(a:comparison_data.differences))
  endif
  
  return l:output
endfunction

" === PRIVATE HELPER FUNCTIONS ===

" Create empty heatmap structure
function! s:empty_heatmap()
  return {
    \ 'keyboard_layout': {},
    \ 'intensity_map': {},
    \ 'color_mapping': {},
    \ 'max_intensity': 0,
    \ 'total_keystrokes': 0
  \ }
endfunction

" Create empty command heatmap structure
function! s:empty_command_heatmap()
  return {
    \ 'top_commands': [],
    \ 'frequency_bars': [],
    \ 'percentages': [],
    \ 'total_commands': 0
  \ }
endfunction

" Create keyboard layout mapping with key positions
function! s:create_keyboard_layout(key_frequencies)
  " Define QWERTY keyboard layout positions
  let l:layout = {
    \ 'row1': ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
    \ 'row2': ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
    \ 'row3': ['z', 'x', 'c', 'v', 'b', 'n', 'm'],
    \ 'special': ['<Esc>', '<Space>', '<CR>', '<Tab>']
  \ }
  
  " Map frequencies to layout positions
  let l:keyboard_map = {}
  for row in keys(l:layout)
    let l:keyboard_map[row] = {}
    for key in l:layout[row]
      let l:keyboard_map[row][key] = {
        \ 'count': get(get(a:key_frequencies, key, {}), 'count', 0),
        \ 'percentage': get(get(a:key_frequencies, key, {}), 'percentage', 0.0)
      \ }
    endfor
  endfor
  
  return l:keyboard_map
endfunction

" Calculate intensity mapping for visualization
function! s:calculate_intensity_map(key_frequencies)
  let l:intensities = {}
  let l:max_count = 0
  
  " Find maximum count for normalization
  for [key, data] in items(a:key_frequencies)
    let l:count = get(data, 'count', 0)
    if l:count > l:max_count
      let l:max_count = l:count
    endif
  endfor
  
  " Calculate normalized intensities (0-10 scale)
  for [key, data] in items(a:key_frequencies)
    let l:count = get(data, 'count', 0)
    if l:max_count > 0
      let l:intensities[key] = float2nr((l:count * 10.0) / l:max_count)
    else
      let l:intensities[key] = 0
    endif
  endfor
  
  return l:intensities
endfunction

" Generate color mapping based on intensity
function! s:generate_color_mapping(key_frequencies)
  let l:color_map = {}
  let l:intensities = s:calculate_intensity_map(a:key_frequencies)
  
  for [key, intensity] in items(l:intensities)
    if intensity >= 8
      let l:color_map[key] = 'high'      " Red/bright
    elseif intensity >= 5
      let l:color_map[key] = 'medium'    " Yellow/orange
    elseif intensity >= 2
      let l:color_map[key] = 'low'       " Green/dim
    else
      let l:color_map[key] = 'minimal'   " Default/gray
    endif
  endfor
  
  return l:color_map
endfunction

" Get maximum intensity value
function! s:get_max_intensity(key_frequencies)
  let l:max_count = 0
  for [key, data] in items(a:key_frequencies)
    let l:count = get(data, 'count', 0)
    if l:count > l:max_count
      let l:max_count = l:count
    endif
  endfor
  return l:max_count
endfunction

" Generate frequency bars for command visualization
function! s:generate_frequency_bars(top_commands)
  let l:bars = []
  let l:max_count = 0
  
  " Find maximum count for bar scaling
  for [cmd, data] in a:top_commands
    let l:count = get(data, 'count', 0)
    if l:count > l:max_count
      let l:max_count = l:count
    endif
  endfor
  
  " Generate bars (max 20 characters wide)
  for [cmd, data] in a:top_commands
    let l:count = get(data, 'count', 0)
    let l:bar_length = l:max_count > 0 ? float2nr((l:count * 20.0) / l:max_count) : 0
    let l:bar = repeat('█', l:bar_length) . repeat(' ', 20 - l:bar_length)
    call add(l:bars, {'command': cmd, 'bar': l:bar, 'count': l:count})
  endfor
  
  return l:bars
endfunction

" Calculate command percentages
function! s:calculate_command_percentages(top_commands)
  let l:percentages = []
  let l:total = 0
  
  " Calculate total count
  for [cmd, data] in a:top_commands
    let l:total += get(data, 'count', 0)
  endfor
  
  " Calculate percentages
  for [cmd, data] in a:top_commands
    let l:count = get(data, 'count', 0)
    let l:percentage = l:total > 0 ? (l:count * 100.0) / l:total : 0.0
    call add(l:percentages, {'command': cmd, 'percentage': l:percentage})
  endfor
  
  return l:percentages
endfunction

" Render keyboard layout to display format
function! s:render_keyboard_layout(heatmap_data)
  let l:output = []
  let l:layout = a:heatmap_data.keyboard_layout
  let l:intensities = a:heatmap_data.intensity_map
  
  call add(l:output, 'KEYBOARD HEATMAP')
  call add(l:output, '─────────────────')
  
  " Row 1: QWERTYUIOP
  let l:row1_display = ''
  for key in ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']
    let l:intensity = get(l:intensities, key, 0)
    let l:display_key = s:format_key_with_intensity(key, l:intensity)
    let l:row1_display .= '[' . l:display_key . ']'
  endfor
  call add(l:output, l:row1_display)
  
  " Row 2: ASDFGHJKL
  let l:row2_display = ' '
  for key in ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l']
    let l:intensity = get(l:intensities, key, 0)
    let l:display_key = s:format_key_with_intensity(key, l:intensity)
    let l:row2_display .= '[' . l:display_key . ']'
  endfor
  call add(l:output, l:row2_display)
  
  " Row 3: ZXCVBNM
  let l:row3_display = '  '
  for key in ['z', 'x', 'c', 'v', 'b', 'n', 'm']
    let l:intensity = get(l:intensities, key, 0)
    let l:display_key = s:format_key_with_intensity(key, l:intensity)
    let l:row3_display .= '[' . l:display_key . ']'
  endfor
  call add(l:output, l:row3_display)
  
  " Special keys
  call add(l:output, '')
  call add(l:output, 'Special Keys:')
  for key in ['<Esc>', '<Space>', '<CR>', '<Tab>']
    let l:intensity = get(l:intensities, key, 0)
    let l:count = get(get(a:heatmap_data.keyboard_layout, 'special', {}), key, {})
    let l:key_count = get(l:count, 'count', 0)
    if l:key_count > 0
      call add(l:output, printf('  %s: %s (%d)', key, s:get_intensity_indicator(l:intensity), l:key_count))
    endif
  endfor
  
  " Legend
  call add(l:output, '')
  call add(l:output, 'Intensity: ░ (low) ▒ (medium) ▓ (high) █ (very high)')
  
  return l:output
endfunction

" Render command frequencies to display format
function! s:render_command_frequencies(heatmap_data)
  let l:output = []
  let l:bars = a:heatmap_data.frequency_bars
  let l:percentages = a:heatmap_data.percentages
  
  call add(l:output, 'TOP COMMANDS')
  call add(l:output, '────────────')
  
  for i in range(len(l:bars))
    let l:bar_data = l:bars[i]
    let l:pct_data = l:percentages[i]
    let l:line = printf('%s: %s %d (%.1f%%)', 
      \ l:bar_data.command, 
      \ l:bar_data.bar, 
      \ l:bar_data.count,
      \ l:pct_data.percentage)
    call add(l:output, l:line)
  endfor
  
  return l:output
endfunction

" Format key with intensity indicator
function! s:format_key_with_intensity(key, intensity)
  let l:indicator = s:get_intensity_indicator(a:intensity)
  return a:key . l:indicator
endfunction

" Get intensity indicator character
function! s:get_intensity_indicator(intensity)
  if a:intensity >= 8
    return '█'      " Very high
  elseif a:intensity >= 6
    return '▓'      " High
  elseif a:intensity >= 3
    return '▒'      " Medium
  elseif a:intensity >= 1
    return '░'      " Low
  else
    return ' '      " Minimal/none
  endif
endfunction

" Calculate differences between two heatmaps
function! s:calculate_heatmap_differences(session_heatmap, historical_heatmap)
  let l:differences = []
  let l:session_intensities = a:session_heatmap.intensity_map
  let l:historical_intensities = a:historical_heatmap.intensity_map
  
  " Find keys with significant differences
  let l:all_keys = extend(copy(keys(l:session_intensities)), keys(l:historical_intensities))
  let l:unique_keys = filter(copy(l:all_keys), 'count(l:all_keys, v:val) == 1')
  
  for key in l:unique_keys
    let l:session_intensity = get(l:session_intensities, key, 0)
    let l:historical_intensity = get(l:historical_intensities, key, 0)
    let l:diff = l:session_intensity - l:historical_intensity
    
    " Only report significant differences (>= 2 intensity levels)
    if abs(l:diff) >= 2
      let l:change_type = l:diff > 0 ? 'increased' : 'decreased'
      call add(l:differences, {
        \ 'key': key,
        \ 'change': l:change_type,
        \ 'difference': abs(l:diff),
        \ 'session_intensity': l:session_intensity,
        \ 'historical_intensity': l:historical_intensity
      \ })
    endif
  endfor
  
  " Sort by difference magnitude
  call sort(l:differences, 's:compare_difference_magnitude')
  
  return l:differences[0:4]  " Top 5 differences
endfunction

" Render differences for display
function! s:render_differences(differences)
  let l:output = []
  
  if empty(a:differences)
    call add(l:output, 'No significant differences detected')
    return l:output
  endif
  
  for diff in a:differences
    let l:change_indicator = diff.change ==# 'increased' ? '↑' : '↓'
    let l:line = printf('%s %s %s (was %s, now %s)',
      \ diff.key,
      \ l:change_indicator,
      \ diff.change,
      \ s:get_intensity_indicator(diff.historical_intensity),
      \ s:get_intensity_indicator(diff.session_intensity))
    call add(l:output, l:line)
  endfor
  
  return l:output
endfunction

" Compare function for sorting commands by frequency
function! s:compare_command_frequency(item1, item2)
  let l:count1 = get(a:item1[1], 'count', 0)
  let l:count2 = get(a:item2[1], 'count', 0)
  return l:count2 - l:count1
endfunction

" Compare function for sorting differences by magnitude
function! s:compare_difference_magnitude(diff1, diff2)
  return a:diff2.difference - a:diff1.difference
endfunction