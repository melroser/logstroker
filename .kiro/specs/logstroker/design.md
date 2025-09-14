# Design Document

## Overview

Logstroker is implemented as a vim plugin that creates a dedicated analysis window for displaying keystroke analytics. The plugin follows vim's standard plugin architecture with autoload functions, configurable key mappings, and a custom buffer-based UI. The core functionality involves parsing vim keylog files, analyzing keystroke patterns, generating heatmap visualizations, and presenting actionable insights in a user-friendly interface.

## Architecture

### Plugin Structure
```
logstroker/
├── plugin/logstroker.vim          # Main plugin entry point and key mappings
├── autoload/logstroker.vim        # Core functionality and public API
├── autoload/logstroker/
│   ├── parser.vim                 # Keylog file parsing logic
│   ├── anal.vim                   # Pattern analysis and statistics
│   ├── heatmap.vim                # Heatmap generation and visualization
│   ├── window.vim                 # Window management and UI
│   └── config.vim                 # Configuration management
└── doc/logstroker.txt             # Documentation
```

### Data Flow
1. User triggers plugin via key mapping (F2)
2. Configuration module loads keylog file path settings
3. Parser module reads and processes keylog file
4. Anal module processes keystroke data and identifies patterns
5. Heatmap module generates visual representations
6. Window module creates and populates the analysis buffer
7. UI displays current session vs historical data with suggestions

## Components and Interfaces

### Configuration Module (`autoload/logstroker/config.vim`)
**Purpose:** Manages plugin settings and keylog file location

**Key Functions:**
- `logstroker#config#get_keylog_path()` - Returns configured keylog file path
- `logstroker#config#set_keylog_path(path)` - Sets keylog file path
- `logstroker#config#load_defaults()` - Loads default configuration values

**Configuration Variables:**
- `g:logstroker_keylog_path` - Path to vim keylog file (default: `~/.vim_keylog`)
- `g:logstroker_toggle_key` - Key mapping to open analysis window (default: `<F2>`)
- `g:logstroker_window_width` - Width of analysis window (default: 50)
- `g:logstroker_auto_refresh` - Auto-refresh interval in seconds (default: 5)

### Parser Module (`autoload/logstroker/parser.vim`)
**Purpose:** Reads and parses vim keylog files into structured data

**Key Functions:**
- `logstroker#parser#read_keylog(filepath)` - Reads keylog file and returns raw data
- `logstroker#parser#parse_keystrokes(raw_data)` - Converts raw keylog into structured keystroke events
- `logstroker#parser#get_session_data()` - Extracts current session keystrokes
- `logstroker#parser#get_historical_data()` - Extracts historical keystroke data

**Data Structures:**
```vim
" Keystroke event structure
{
  'key': 'j',
  'timestamp': '2024-01-15 14:30:25',
  'mode': 'normal',
  'context': 'movement'
}
```

### Anal Module (`autoload/logstroker/anal.vim`)
**Purpose:** Analyzes keystroke patterns and generates insights

**Key Functions:**
- `logstroker#anal#analyze_patterns(keystrokes)` - Identifies usage patterns and frequencies
- `logstroker#anal#generate_suggestions(analysis)` - Creates ergonomic and efficiency suggestions
- `logstroker#anal#calculate_stats(keystrokes)` - Computes keystroke statistics
- `logstroker#anal#detect_inefficiencies(patterns)` - Identifies problematic usage patterns

**Anal Categories:**
- **Movement Anal:** hjkl vs arrow keys, word vs character movement
- **Mode Switching:** ESC usage, alternative mode switching patterns
- **Editing Patterns:** Repetitive operations, macro opportunities
- **Navigation Efficiency:** Search usage, buffer switching, file navigation

### Heatmap Module (`autoload/logstroker/heatmap.vim`)
**Purpose:** Generates visual heatmap representations of keystroke data

**Key Functions:**
- `logstroker#heatmap#generate_keyboard_heatmap(stats)` - Creates keyboard layout heatmap
- `logstroker#heatmap#generate_command_heatmap(commands)` - Creates command frequency heatmap
- `logstroker#heatmap#render_heatmap(heatmap_data)` - Converts heatmap data to display format

**Visualization Elements:**
- ASCII keyboard layout with intensity indicators
- Color coding using vim highlight groups
- Frequency bars and percentage indicators
- Session vs historical comparison views

### Window Module (`autoload/logstroker/window.vim`)
**Purpose:** Manages the analysis window UI and user interactions

**Key Functions:**
- `logstroker#window#toggle()` - Opens/closes the analysis window
- `logstroker#window#create_buffer()` - Creates and configures the analysis buffer
- `logstroker#window#update_content()` - Refreshes window content with latest data
- `logstroker#window#setup_keymaps()` - Configures window-specific key mappings

**Window Layout:**
```
┌─ Logstroker Anal ─────────────────────────┐
│ Session: 45 min | Total: 12.3 hours       │
├───────────────────────────────────────────┤
│ KEYBOARD HEATMAP                          │
│ [q][w][e][r][t][y][u][i][o][p]            │
│  [a][s][d][f][g][h][j][k][l]              │
│   [z][x][c][v][b][n][m]                   │
│                                           │
│ TOP COMMANDS (Current Session)            │
│ j: ████████████ 45 (23%)                  │
│ k: ██████████   38 (19%)                  │
│ h: ████████     28 (14%)                  │
│                                           │
│ SUGGESTIONS                               │
│ • Use 'w' instead of repeated 'l'         │
│ • Consider ':' instead of ESC then ':'    │
│ • Try 'A' instead of '$' then 'a'         │
└───────────────────────────────────────────┘
```

## Data Models

### Keystroke Event
```vim
{
  'key': string,           " The actual key pressed
  'timestamp': string,     " When the keystroke occurred
  'mode': string,          " Vim mode (normal, insert, visual, command)
  'sequence': number,      " Position in keystroke sequence
  'session_id': string     " Identifier for vim session
}
```

### Anal Result
```vim
{
  'total_keystrokes': number,
  'session_keystrokes': number,
  'key_frequencies': {},
  'command_patterns': [],
  'inefficiencies': [],
  'suggestions': []
}
```

### Heatmap Data
```vim
{
  'keyboard_layout': {},   " Key positions and intensities
  'command_frequencies': {},
  'session_comparison': {},
  'color_mapping': {}
}
```

## Error Handling

### File Access Errors
- **Missing keylog file:** Display helpful message with setup instructions
- **Permission errors:** Show clear error message and suggest file permission fixes
- **Corrupted keylog:** Gracefully handle malformed data and continue with valid entries

### Plugin Integration Errors
- **Key mapping conflicts:** Detect and warn about conflicting key mappings
- **Window creation failures:** Fall back to command-line output if window creation fails
- **Memory constraints:** Implement data pagination for large keylog files

### Configuration Errors
- **Invalid paths:** Validate file paths and provide default fallbacks
- **Invalid settings:** Use sensible defaults for invalid configuration values
- **Missing dependencies:** Check for required vim features and provide clear error messages

## Testing Strategy

### Unit Testing
- **Parser module:** Test keylog parsing with various file formats and edge cases
- **Anal module:** Verify pattern detection and suggestion generation accuracy
- **Heatmap module:** Test visualization generation with different data sets
- **Configuration module:** Test setting validation and persistence

### Integration Testing
- **Window management:** Test window creation, updates, and cleanup
- **Key mapping integration:** Verify plugin activation and deactivation
- **File monitoring:** Test real-time keylog file updates and refresh behavior
- **Cross-platform compatibility:** Test on different vim versions and operating systems

### User Acceptance Testing
- **Usability testing:** Verify intuitive interface and clear suggestions
- **Performance testing:** Ensure responsive behavior with large keylog files
- **Accessibility testing:** Test with different vim configurations and color schemes
- **Documentation testing:** Verify setup instructions and usage examples