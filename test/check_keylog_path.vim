" Check what keylog path is being used and what files exist

source autoload/logstroker/config.vim
source autoload/logstroker/parser.vim

call logstroker#config#load_defaults()

echo "=== Keylog Path Check ==="
let keylog_path = logstroker#config#get_keylog_path()
echo "Configured path: " . keylog_path
echo "Path exists: " . (isdirectory(keylog_path) ? "YES" : "NO")

if isdirectory(keylog_path)
  echo "Files in directory:"
  let files = glob(keylog_path . '/*', 0, 1)
  for file in files
    echo "  " . file
  endfor
  
  echo "Vimlog files specifically:"
  let vimlog_files = glob(keylog_path . '/vimlog*.txt', 0, 1)
  for file in vimlog_files
    echo "  " . file . " (size: " . getfsize(file) . " bytes)"
  endfor
else
  echo "Directory does not exist!"
  echo "Checking ~/.vim/vimlog instead:"
  let alt_path = expand('~/.vim/vimlog')
  echo "Alt path: " . alt_path
  echo "Alt path exists: " . (isdirectory(alt_path) ? "YES" : "NO")
  
  if isdirectory(alt_path)
    let alt_files = glob(alt_path . '/*', 0, 1)
    for file in alt_files
      echo "  " . file
    endfor
  endif
endif