# Logstroker

A Vim plugin for analyzing keystroke patterns and providing ergonomic and efficiency suggestions.

## Features

- **Keystroke Analysis**: Analyzes vim keylog files to detect usage patterns
- **Efficiency Detection**: Identifies inefficient patterns like arrow key overuse, excessive ESC usage
- **Smart Suggestions**: Provides prioritized recommendations for better vim usage
- **Statistical Analysis**: Calculates efficiency and ergonomic scores (0-100)
- **Pattern Recognition**: Detects movement, editing, and navigation patterns

## Installation

### Using vim-plug
```vim
Plug 'your-username/logstroker'
```

### Manual Installation
1. Clone this repository to your vim plugin directory:
   ```bash
   git clone https://github.com/your-username/logstroker.git ~/.vim/pack/plugins/start/logstroker
   ```

## Configuration

Add to your `.vimrc`:

```vim
" Set keylog directory (default: ~/.vim/vimlog)
let g:logstroker_keylog_path = '~/.vim/vimlog'

" Set toggle key (default: <F2>)
let g:logstroker_toggle_key = '<F2>'

" Set analysis window width (default: 50)
let g:logstroker_window_width = 50

" Enable/disable suggestion categories
let g:logstroker_enable_ergonomic_suggestions = 1
let g:logstroker_enable_efficiency_suggestions = 1
let g:logstroker_enable_navigation_suggestions = 1
```

## Usage

### Basic Commands
- `:LogstrokerAnalyze` - Analyze current session keystrokes
- `:LogstrokerToggle` - Toggle analysis window
- `:LogstrokerStats` - Show keystroke statistics

### Analyzing Your Keystrokes

1. **Set up keylogging** (requires separate vim keylog setup)
2. **Run analysis**:
   ```vim
   :LogstrokerAnalyze
   ```
3. **View suggestions** in the analysis window

## Analysis Features

### Pattern Detection
- **Movement patterns**: hjkl vs arrow keys, word vs character movement
- **Mode switching**: ESC usage, insert mode patterns
- **Editing patterns**: Repetitive sequences, inefficient selections
- **Navigation patterns**: Search usage, jump commands

### Suggestions
- **Ergonomic**: Reduce hand movement (hjkl over arrows, ESC alternatives)
- **Efficiency**: Word-based movement, search navigation, macro usage
- **Navigation**: Better use of vim's powerful navigation features

### Scoring
- **Efficiency Score** (0-100): Based on keystroke efficiency
- **Ergonomic Score** (0-100): Based on hand movement and strain

## Development

### Running Tests
```bash
# Run all tests
vim -c "source test/test_logstroker.vim" -c ":q"

# Run parser tests only
vim -c "source autoload/logstroker/test.vim | call logstroker#test#run_parser_tests()" -c ":q"
```

### Project Structure
```
logstroker/
├── autoload/logstroker/    # Core plugin modules
│   ├── anal.vim           # Analysis engine
│   ├── parser.vim         # Keylog parsing
│   ├── config.vim         # Configuration
│   ├── window.vim         # UI components
│   └── test.vim           # Parser tests
├── plugin/                # Plugin initialization
├── doc/                   # Documentation
├── test/                  # Unit tests
│   └── test_logstroker.vim
└── .kiro/specs/           # Development specs
```

## Requirements

- Vim 8.0+ or Neovim
- Keylog files in vim keylog format

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## Changelog

### v1.0.0 (Initial Release)
- Keystroke pattern analysis
- Efficiency and ergonomic scoring
- Smart suggestion generation
- Comprehensive test suite