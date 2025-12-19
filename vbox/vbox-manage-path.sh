#!/bin/sh

set -e

# 1. Ищем в PATH
if command -v VBoxManage >/dev/null; then
  echo VBoxManage
  exit 0
fi

# 2. Windows (в Git Bash / MSYS2)
if [ -n "$WINDIR" ] || [ -n "$OS" ] && [ "$OS" = "Windows_NT" ]; then
  candidate="C:\\Program Files\\Oracle\\VirtualBox\\VBoxManage.exe"
  if [ -f "$candidate" ]; then
    echo "$candidate"
    exit 0
  fi
fi

# 3. macOS
if [ "$(uname)" = "Darwin" ]; then
  candidate="/Applications/VirtualBox.app/Contents/MacOS/VBoxManage"
  if [ -f "$candidate" ]; then
    echo "$candidate"
    exit 0
  fi
fi

exit 1
