" autoload/logstroker/anal.vim - Keystroke analysis engine
" Author: Logstroker Plugin
" Version: 1.0

" Main analysis function that processes keystroke data and returns comprehensive analysis
function! logstroker#anal#analyze_patterns(keystrokes)
  if empty(a:keystrokes)
    return s:empty_analysis_result()
  endif
  
  let l:analysis = {
    \ 'total_keystrokes': len(a:keystrokes),
    \ 'session_keystrokes': s:count_session_keystrokes(a:keystrokes),
    \ 'key_frequencies': s:calculate_key_frequencies(a:keystrokes),
    \ 'command_patterns': s:detect_command_patterns(a:keystrokes),
    \ 'movement_patterns': s:analyze_movement_patterns(a:keystrokes),
    \ 'mode_switching': s:analyze_mode_switching(a:keystrokes),
    \ 'inefficiencies': s:detect_inefficiencies(a:keystrokes),
    \ 'suggestions': [],
    \ 'statistics': s:calculate_statistics(a:keystrokes)
  \ }
  
  " Generate suggestions based on detected patterns and inefficiencies
  let l:analysis.suggestions = logstroker#anal#generate_suggestions(l:analysis)
  
  return l:analysis
endfunction

" Calculate keystroke frequency statistics
function! logstroker#anal#calculate_stats(keystrokes)
  return s:calculate_statistics(a:keystrokes)
endfunction

" Detect inefficient usage patterns
function! logstroker#anal#detect_inefficiencies(patterns)
  " This function can work with either raw keystrokes or analysis patterns
  if has_key(a:patterns, 'key_frequencies')
    " Already analyzed patterns
    return s:detect_inefficiencies_from_analysis(a:patterns)
  else
    " Raw keystrokes
    return s:detect_inefficiencies(a:patterns)
  endif
endfunction

" Generate ergonomic and efficiency suggestions based on analysis
function! logstroker#anal#generate_suggestions(analysis)
  let l:suggestions = []
  
  " Add movement-based suggestions
  call extend(l:suggestions, s:generate_movement_suggestions(a:analysis))
  
  " Add mode switching suggestions
  call extend(l:suggestions, s:generate_mode_switching_suggestions(a:analysis))
  
  " Add editing efficiency suggestions
  call extend(l:suggestions, s:generate_editing_suggestions(a:analysis))
  
  " Add navigation suggestions
  call extend(l:suggestions, s:generate_navigation_suggestions(a:analysis))
  
  " Sort suggestions by priority (highest impact first)
  call sort(l:suggestions, 's:compare_suggestion_priority')
  
  return l:suggestions
endfunction

" === PRIVATE HELPER FUNCTIONS ===

" Return empty analysis result structure
function! s:empty_analysis_result()
  return {
    \ 'total_keystrokes': 0,
    \ 'session_keystrokes': 0,
    \ 'key_frequencies': {},
    \ 'command_patterns': [],
    \ 'movement_patterns': {},
    \ 'mode_switching': {},
    \ 'inefficiencies': [],
    \ 'suggestions': [],
    \ 'statistics': {}
  \ }
endfunction

" Count keystrokes from current session
function! s:count_session_keystrokes(keystrokes)
  let l:current_session = logstroker#parser#get_session_id()
  let l:count = 0
  
  for keystroke in a:keystrokes
    if get(keystroke, 'session_id', '') ==# l:current_session
      let l:count += 1
    endif
  endfor
  
  return l:count
endfunction

" Calculate frequency of each key
function! s:calculate_key_frequencies(keystrokes)
  let l:frequencies = {}
  let l:total = len(a:keystrokes)
  
  for keystroke in a:keystrokes
    let l:key = keystroke.key
    let l:frequencies[l:key] = get(l:frequencies, l:key, 0) + 1
  endfor
  
  " Convert to percentages and add metadata
  let l:result = {}
  for [key, key_count] in items(l:frequencies)
    let l:result[key] = {
      \ 'count': key_count,
      \ 'percentage': l:total > 0 ? (key_count * 100.0) / l:total : 0,
      \ 'context': s:get_key_context(key)
    \ }
  endfor
  
  return l:result
endfunction

" Detect command patterns and sequences
function! s:detect_command_patterns(keystrokes)
  let l:patterns = []
  let l:sequence = []
  let l:i = 0
  
  while l:i < len(a:keystrokes)
    let l:keystroke = a:keystrokes[l:i]
    
    " Look for common command sequences
    if l:keystroke.key ==# ':'
      " Command mode sequence
      let l:cmd_sequence = s:extract_command_sequence(a:keystrokes, l:i)
      if !empty(l:cmd_sequence.pattern)
        call add(l:patterns, l:cmd_sequence)
        let l:i = l:cmd_sequence.end_index
      endif
    elseif l:keystroke.context ==# 'editing'
      " Editing command sequence
      let l:edit_sequence = s:extract_editing_sequence(a:keystrokes, l:i)
      if !empty(l:edit_sequence.pattern)
        call add(l:patterns, l:edit_sequence)
        let l:i = l:edit_sequence.end_index
      endif
    endif
    
    let l:i += 1
  endwhile
  
  return l:patterns
endfunction

" Analyze movement patterns for efficiency
function! s:analyze_movement_patterns(keystrokes)
  let l:movement_stats = {
    \ 'hjkl_usage': 0,
    \ 'arrow_key_usage': 0,
    \ 'word_movement': 0,
    \ 'character_movement': 0,
    \ 'line_movement': 0,
    \ 'search_movement': 0,
    \ 'repetitive_sequences': []
  \ }
  
  let l:sequence = []
  
  for keystroke in a:keystrokes
    if keystroke.context ==# 'movement'
      " Count different types of movement
      if keystroke.key =~# '^[hjkl]$'
        let l:movement_stats.hjkl_usage += 1
        let l:movement_stats.character_movement += 1
      elseif keystroke.key =~# '^<\(Up\|Down\|Left\|Right\)>$'
        let l:movement_stats.arrow_key_usage += 1
        let l:movement_stats.character_movement += 1
      elseif keystroke.key =~# '^[wbeWBE]$'
        let l:movement_stats.word_movement += 1
      elseif keystroke.key =~# '^[0$^]$'
        let l:movement_stats.line_movement += 1
      elseif keystroke.key =~# '^[/?nNfFtT]$'
        let l:movement_stats.search_movement += 1
      endif
      
      " Track sequences for repetitive pattern detection
      call add(l:sequence, keystroke.key)
      if len(l:sequence) > 10
        call remove(l:sequence, 0)
      endif
      
      " Detect repetitive sequences
      let l:repetitive = s:find_repetitive_patterns(l:sequence)
      if !empty(l:repetitive)
        call add(l:movement_stats.repetitive_sequences, l:repetitive)
      endif
    else
      " Reset sequence on non-movement keys
      let l:sequence = []
    endif
  endfor
  
  return l:movement_stats
endfunction

" Analyze mode switching patterns
function! s:analyze_mode_switching(keystrokes)
  let l:mode_stats = {
    \ 'esc_usage': 0,
    \ 'insert_entries': 0,
    \ 'mode_switches': 0,
    \ 'average_insert_duration': 0,
    \ 'excessive_esc_sequences': []
  \ }
  
  let l:current_mode = 'normal'
  let l:insert_start = -1
  let l:insert_durations = []
  let l:esc_sequence = []
  
  for i in range(len(a:keystrokes))
    let l:keystroke = a:keystrokes[i]
    
    if l:keystroke.key ==# '<Esc>'
      let l:mode_stats.esc_usage += 1
      call add(l:esc_sequence, i)
      
      if l:current_mode ==# 'insert' && l:insert_start >= 0
        call add(l:insert_durations, i - l:insert_start)
      endif
      
      let l:current_mode = 'normal'
    elseif l:keystroke.context ==# 'mode_switch' && l:keystroke.key !=# '<Esc>'
      let l:mode_stats.insert_entries += 1
      let l:mode_stats.mode_switches += 1
      let l:current_mode = 'insert'
      let l:insert_start = i
      let l:esc_sequence = []
    endif
    
    " Detect excessive ESC usage (multiple ESCs in short sequence)
    if len(l:esc_sequence) > 1
      let l:recent_escs = filter(copy(l:esc_sequence), 'v:val > i - 5')
      if len(l:recent_escs) >= 2
        call add(l:mode_stats.excessive_esc_sequences, l:recent_escs)
      endif
    endif
  endfor
  
  " Calculate average insert mode duration
  if len(l:insert_durations) > 0
    let l:mode_stats.average_insert_duration = s:average(l:insert_durations)
  endif
  
  return l:mode_stats
endfunction

" Detect various inefficiency patterns
function! s:detect_inefficiencies(keystrokes)
  let l:inefficiencies = []
  
  " Detect arrow key overuse
  let l:arrow_inefficiency = s:detect_arrow_key_overuse(a:keystrokes)
  if !empty(l:arrow_inefficiency)
    call add(l:inefficiencies, l:arrow_inefficiency)
  endif
  
  " Detect excessive ESC usage
  let l:esc_inefficiency = s:detect_excessive_esc(a:keystrokes)
  if !empty(l:esc_inefficiency)
    call add(l:inefficiencies, l:esc_inefficiency)
  endif
  
  " Detect character-by-character movement
  let l:char_movement = s:detect_character_movement_overuse(a:keystrokes)
  if !empty(l:char_movement)
    call add(l:inefficiencies, l:char_movement)
  endif
  
  " Detect repetitive editing patterns
  let l:repetitive_editing = s:detect_repetitive_editing(a:keystrokes)
  if !empty(l:repetitive_editing)
    call extend(l:inefficiencies, l:repetitive_editing)
  endif
  
  " Detect inefficient text selection
  let l:selection_inefficiency = s:detect_inefficient_selection(a:keystrokes)
  if !empty(l:selection_inefficiency)
    call add(l:inefficiencies, l:selection_inefficiency)
  endif
  
  return l:inefficiencies
endfunction

" Calculate comprehensive statistics
function! s:calculate_statistics(keystrokes)
  let l:stats = {
    \ 'total_keystrokes': len(a:keystrokes),
    \ 'keys_per_context': {},
    \ 'mode_distribution': {},
    \ 'efficiency_score': 0,
    \ 'ergonomic_score': 0,
    \ 'top_keys': [],
    \ 'session_summary': {}
  \ }
  
  " Count keystrokes by context
  for keystroke in a:keystrokes
    let l:context = get(keystroke, 'context', 'other')
    let l:stats.keys_per_context[l:context] = get(l:stats.keys_per_context, l:context, 0) + 1
    
    let l:mode = get(keystroke, 'mode', 'normal')
    let l:stats.mode_distribution[l:mode] = get(l:stats.mode_distribution, l:mode, 0) + 1
  endfor
  
  " Calculate efficiency and ergonomic scores
  let l:stats.efficiency_score = s:calculate_efficiency_score(a:keystrokes)
  let l:stats.ergonomic_score = s:calculate_ergonomic_score(a:keystrokes)
  
  " Get top 10 most used keys
  let l:frequencies = s:calculate_key_frequencies(a:keystrokes)
  let l:sorted_keys = sort(items(l:frequencies), 's:compare_frequency')
  let l:stats.top_keys = l:sorted_keys[0:9]
  
  return l:stats
endfunction

" === SUGGESTION GENERATION FUNCTIONS ===

" Generate movement-related suggestions
function! s:generate_movement_suggestions(analysis)
  let l:suggestions = []
  let l:movement = a:analysis.movement_patterns
  
  " Arrow key suggestions
  if l:movement.arrow_key_usage > l:movement.hjkl_usage
    call add(l:suggestions, {
      \ 'type': 'ergonomic',
      \ 'priority': 'high',
      \ 'title': 'Use hjkl instead of arrow keys',
      \ 'description': 'Arrow keys require hand movement. Use hjkl for more efficient navigation.',
      \ 'current_pattern': 'Arrow keys: ' . l:movement.arrow_key_usage . ' times',
      \ 'suggested_alternative': 'Use h(left), j(down), k(up), l(right)',
      \ 'impact': 'Reduces hand movement and improves typing speed'
    \ })
  endif
  
  " Character vs word movement
  if l:movement.character_movement > (l:movement.word_movement * 3)
    call add(l:suggestions, {
      \ 'type': 'efficiency',
      \ 'priority': 'medium',
      \ 'title': 'Use word-based movement',
      \ 'description': 'Reduce character-by-character movement with word navigation.',
      \ 'current_pattern': 'Character movement: ' . l:movement.character_movement . ' times',
      \ 'suggested_alternative': 'Use w(word), b(back), e(end) for faster navigation',
      \ 'impact': 'Significantly reduces keystrokes for navigation'
    \ })
  endif
  
  return l:suggestions
endfunction

" Generate mode switching suggestions
function! s:generate_mode_switching_suggestions(analysis)
  let l:suggestions = []
  let l:mode_switching = a:analysis.mode_switching
  
  " Excessive ESC usage
  if l:mode_switching.esc_usage > (l:mode_switching.insert_entries * 1.5)
    call add(l:suggestions, {
      \ 'type': 'ergonomic',
      \ 'priority': 'high',
      \ 'title': 'Reduce ESC key usage',
      \ 'description': 'ESC key is hard to reach. Consider alternatives.',
      \ 'current_pattern': 'ESC usage: ' . l:mode_switching.esc_usage . ' times',
      \ 'suggested_alternative': 'Use Ctrl+[ or jj mapping to exit insert mode',
      \ 'impact': 'Reduces finger strain and improves ergonomics'
    \ })
  endif
  
  return l:suggestions
endfunction

" Generate editing efficiency suggestions
function! s:generate_editing_suggestions(analysis)
  let l:suggestions = []
  
  " Look for repetitive patterns in command_patterns
  for pattern in a:analysis.command_patterns
    if get(pattern, 'repetitive', 0)
      call add(l:suggestions, {
        \ 'type': 'efficiency',
        \ 'priority': 'medium',
        \ 'title': 'Use macros for repetitive editing',
        \ 'description': 'Detected repetitive editing pattern.',
        \ 'current_pattern': 'Repeated: ' . get(pattern, 'pattern', ''),
        \ 'suggested_alternative': 'Record macro with q, replay with @',
        \ 'impact': 'Eliminates repetitive keystrokes'
      \ })
    endif
  endfor
  
  return l:suggestions
endfunction

" Generate navigation suggestions
function! s:generate_navigation_suggestions(analysis)
  let l:suggestions = []
  let l:movement = a:analysis.movement_patterns
  
  " Low search usage suggests inefficient navigation
  if l:movement.search_movement < (l:movement.character_movement / 10)
    call add(l:suggestions, {
      \ 'type': 'efficiency',
      \ 'priority': 'medium',
      \ 'title': 'Use search for navigation',
      \ 'description': 'Search is often faster than manual navigation.',
      \ 'current_pattern': 'Low search usage: ' . l:movement.search_movement . ' times',
      \ 'suggested_alternative': 'Use /(search), f(find char), t(till char)',
      \ 'impact': 'Faster navigation to specific locations'
    \ })
  endif
  
  return l:suggestions
endfunction

" === PATTERN DETECTION HELPER FUNCTIONS ===

" Detect arrow key overuse
function! s:detect_arrow_key_overuse(keystrokes)
  let l:arrow_count = 0
  let l:hjkl_count = 0
  
  for keystroke in a:keystrokes
    if keystroke.key =~# '^<\(Up\|Down\|Left\|Right\)>$'
      let l:arrow_count += 1
    elseif keystroke.key =~# '^[hjkl]$'
      let l:hjkl_count += 1
    endif
  endfor
  
  if l:arrow_count > l:hjkl_count && l:arrow_count > 10
    return {
      \ 'type': 'arrow_key_overuse',
      \ 'severity': 'medium',
      \ 'arrow_usage': l:arrow_count,
      \ 'hjkl_usage': l:hjkl_count,
      \ 'description': 'Excessive arrow key usage detected'
    \ }
  endif
  
  return {}
endfunction

" Detect excessive ESC usage
function! s:detect_excessive_esc(keystrokes)
  let l:esc_count = 0
  let l:insert_count = 0
  
  for keystroke in a:keystrokes
    if keystroke.key ==# '<Esc>'
      let l:esc_count += 1
    elseif keystroke.context ==# 'mode_switch' && keystroke.key !=# '<Esc>'
      let l:insert_count += 1
    endif
  endfor
  
  if l:esc_count > (l:insert_count * 1.5) && l:esc_count > 5
    return {
      \ 'type': 'excessive_esc',
      \ 'severity': 'high',
      \ 'esc_usage': l:esc_count,
      \ 'insert_entries': l:insert_count,
      \ 'description': 'Excessive ESC key usage detected'
    \ }
  endif
  
  return {}
endfunction

" Detect character movement overuse
function! s:detect_character_movement_overuse(keystrokes)
  let l:char_movement = 0
  let l:word_movement = 0
  
  for keystroke in a:keystrokes
    if keystroke.context ==# 'movement'
      if keystroke.key =~# '^[hjkl]$' || keystroke.key =~# '^<\(Up\|Down\|Left\|Right\)>$'
        let l:char_movement += 1
      elseif keystroke.key =~# '^[wbeWBE]$'
        let l:word_movement += 1
      endif
    endif
  endfor
  
  if l:char_movement > (l:word_movement * 5) && l:char_movement > 20
    return {
      \ 'type': 'character_movement_overuse',
      \ 'severity': 'medium',
      \ 'character_movement': l:char_movement,
      \ 'word_movement': l:word_movement,
      \ 'description': 'Excessive character-by-character movement'
    \ }
  endif
  
  return {}
endfunction

" Detect repetitive editing patterns
function! s:detect_repetitive_editing(keystrokes)
  let l:patterns = []
  let l:sequence = []
  
  " Need at least 3 keystrokes to detect patterns
  if len(a:keystrokes) < 3
    return l:patterns
  endif
  
  " Look for repeated sequences of 3+ keystrokes
  for i in range(len(a:keystrokes) - 2)
    let l:seq = [a:keystrokes[i].key, a:keystrokes[i+1].key, a:keystrokes[i+2].key]
    
    " Count occurrences of this sequence
    let l:seq_count = 1
    let l:max_j = len(a:keystrokes) - 3
    if l:max_j >= i + 3
      for j in range(i + 3, l:max_j)
        let l:next_seq = [a:keystrokes[j].key, a:keystrokes[j+1].key, a:keystrokes[j+2].key]
        if l:seq == l:next_seq
          let l:seq_count += 1
        endif
      endfor
    endif
    
    if l:seq_count >= 3
      call add(l:patterns, {
        \ 'type': 'repetitive_editing',
        \ 'severity': 'medium',
        \ 'pattern': join(l:seq, ''),
        \ 'occurrences': l:seq_count,
        \ 'description': 'Repetitive editing pattern detected'
      \ })
    endif
  endfor
  
  return l:patterns
endfunction

" Detect inefficient text selection
function! s:detect_inefficient_selection(keystrokes)
  " Look for manual character-by-character selection instead of text objects
  let l:manual_selection = 0
  let l:in_visual = 0
  
  for keystroke in a:keystrokes
    if keystroke.key ==# 'v'
      let l:in_visual = 1
    elseif keystroke.key ==# '<Esc>' || keystroke.context ==# 'editing'
      let l:in_visual = 0
    elseif l:in_visual && keystroke.key =~# '^[hjkl]$'
      let l:manual_selection += 1
    endif
  endfor
  
  if l:manual_selection > 10
    return {
      \ 'type': 'inefficient_selection',
      \ 'severity': 'low',
      \ 'manual_selections': l:manual_selection,
      \ 'description': 'Manual character selection instead of text objects'
    \ }
  endif
  
  return {}
endfunction

" === UTILITY FUNCTIONS ===

" Get context for a specific key
function! s:get_key_context(key)
  if a:key =~# '^[hjklwbeWBE0$^]$'
    return 'movement'
  elseif a:key =~# '^<\(Up\|Down\|Left\|Right\)>$'
    return 'movement'
  elseif a:key =~# '^[xXdDcCsSyYpP]$'
    return 'editing'
  elseif a:key =~# '^[iIaAoO]$' || a:key ==# '<Esc>'
    return 'mode_switch'
  elseif a:key =~# '^[/?nNfFtT]$'
    return 'navigation'
  elseif a:key ==# ':'
    return 'command'
  else
    return 'other'
  endif
endfunction

" Extract command sequence starting at index
function! s:extract_command_sequence(keystrokes, start_index)
  let l:sequence = {'pattern': '', 'end_index': a:start_index, 'type': 'command'}
  let l:i = a:start_index
  
  while l:i < len(a:keystrokes) && (a:keystrokes[l:i].key !=# '<CR>' && a:keystrokes[l:i].key !=# '<Esc>')
    let l:sequence.pattern .= a:keystrokes[l:i].key
    let l:i += 1
  endwhile
  
  let l:sequence.end_index = l:i
  return l:sequence
endfunction

" Extract editing sequence starting at index
function! s:extract_editing_sequence(keystrokes, start_index)
  let l:sequence = {'pattern': '', 'end_index': a:start_index, 'type': 'editing'}
  let l:i = a:start_index
  
  " Capture editing command and any following motions
  while l:i < len(a:keystrokes) && l:i < a:start_index + 5
    let l:keystroke = a:keystrokes[l:i]
    if l:keystroke.context ==# 'editing' || l:keystroke.context ==# 'movement'
      let l:sequence.pattern .= l:keystroke.key
      let l:i += 1
    else
      break
    endif
  endwhile
  
  let l:sequence.end_index = l:i
  return l:sequence
endfunction

" Find repetitive patterns in a sequence
function! s:find_repetitive_patterns(sequence)
  if len(a:sequence) < 6
    return {}
  endif
  
  " Look for patterns of length 2-3 that repeat
  for pattern_len in [2, 3]
    for start in range(len(a:sequence) - pattern_len * 2)
      let l:pattern = a:sequence[start:start + pattern_len - 1]
      let l:next_pattern = a:sequence[start + pattern_len:start + pattern_len * 2 - 1]
      
      if l:pattern == l:next_pattern
        return {
          \ 'pattern': join(l:pattern, ''),
          \ 'length': pattern_len,
          \ 'repetitive': 1
        \ }
      endif
    endfor
  endfor
  
  return {}
endfunction

" Calculate average of a list of numbers
function! s:average(numbers)
  if empty(a:numbers)
    return 0
  endif
  
  let l:sum = 0
  for num in a:numbers
    let l:sum += num
  endfor
  
  return l:sum / len(a:numbers)
endfunction

" Calculate efficiency score (0-100)
function! s:calculate_efficiency_score(keystrokes)
  let l:score = 100
  let l:total = len(a:keystrokes)
  
  if l:total == 0
    return 0
  endif
  
  " Penalize arrow key usage
  let l:arrow_count = 0
  let l:char_movement = 0
  let l:word_movement = 0
  
  for keystroke in a:keystrokes
    if keystroke.key =~# '^<\(Up\|Down\|Left\|Right\)>$'
      let l:arrow_count += 1
    elseif keystroke.key =~# '^[hjkl]$'
      let l:char_movement += 1
    elseif keystroke.key =~# '^[wbeWBE]$'
      let l:word_movement += 1
    endif
  endfor
  
  " Deduct points for inefficiencies
  let l:arrow_penalty = (l:arrow_count * 100) / l:total
  let l:char_movement_penalty = l:word_movement > 0 ? (l:char_movement * 20) / (l:word_movement * l:total) : 0
  
  let l:score -= l:arrow_penalty
  let l:score -= l:char_movement_penalty
  
  return max([0, min([100, l:score])])
endfunction

" Calculate ergonomic score (0-100)
function! s:calculate_ergonomic_score(keystrokes)
  let l:score = 100
  let l:total = len(a:keystrokes)
  
  if l:total == 0
    return 0
  endif
  
  let l:esc_count = 0
  let l:arrow_count = 0
  
  for keystroke in a:keystrokes
    if keystroke.key ==# '<Esc>'
      let l:esc_count += 1
    elseif keystroke.key =~# '^<\(Up\|Down\|Left\|Right\)>$'
      let l:arrow_count += 1
    endif
  endfor
  
  " Deduct points for ergonomic issues
  let l:esc_penalty = (l:esc_count * 50) / l:total
  let l:arrow_penalty = (l:arrow_count * 30) / l:total
  
  let l:score -= l:esc_penalty
  let l:score -= l:arrow_penalty
  
  return max([0, min([100, l:score])])
endfunction

" Compare function for sorting suggestions by priority
function! s:compare_suggestion_priority(s1, s2)
  let l:priority_order = {'high': 3, 'medium': 2, 'low': 1}
  let l:p1 = get(l:priority_order, a:s1.priority, 0)
  let l:p2 = get(l:priority_order, a:s2.priority, 0)
  return l:p2 - l:p1
endfunction

" Compare function for sorting by frequency
function! s:compare_frequency(item1, item2)
  return a:item2[1]['count'] - a:item1[1]['count']
endfunction

" Detect inefficiencies from already analyzed patterns
function! s:detect_inefficiencies_from_analysis(analysis)
  let l:inefficiencies = []
  
  " Check movement patterns
  if has_key(a:analysis, 'movement_patterns')
    let l:movement = a:analysis.movement_patterns
    if l:movement.arrow_key_usage > l:movement.hjkl_usage
      call add(l:inefficiencies, {
        \ 'type': 'arrow_key_preference',
        \ 'severity': 'medium',
        \ 'description': 'Prefers arrow keys over hjkl'
      \ })
    endif
  endif
  
  " Check mode switching patterns
  if has_key(a:analysis, 'mode_switching')
    let l:mode_switching = a:analysis.mode_switching
    if l:mode_switching.esc_usage > (l:mode_switching.insert_entries * 1.5)
      call add(l:inefficiencies, {
        \ 'type': 'excessive_esc',
        \ 'severity': 'high',
        \ 'description': 'Excessive ESC key usage'
      \ })
    endif
  endif
  
  return l:inefficiencies
endfunction