#!/bin/bash
# safe-rm.sh — move files to trash instead of deleting permanently
# Usage: ./safe-rm.sh file1 file2 ...

TRASH="$HOME/.trash"
mkdir -p "$TRASH"

if [ $# -eq 0 ]; then
  echo "Usage: safe-rm.sh file [file...]" >&2
  exit 1
fi

for file in "$@"; do
  if [ -e "$file" ]; then
    mv "$file" "$TRASH/"
    echo "🗑  Moved to trash: $file"
  else
    echo "Not found: $file" >&2
  fi
done

echo ""
echo "Trash is at $TRASH — use 'rm -rf $TRASH' to empty it"
