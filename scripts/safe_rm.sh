#!/bin/bash
# safe_rm.sh — move files to trash instead of permanent delete
# Usage: ./safe_rm.sh file1 file2 ...

TRASH="$HOME/.trash"
mkdir -p "$TRASH"

if [ $# -eq 0 ]; then
  echo "Usage: safe_rm file [file ...]" >&2
  exit 1
fi

for file in "$@"; do
  if [ ! -e "$file" ]; then
    echo "safe_rm: $file: No such file" >&2
    continue
  fi
  # Add timestamp to avoid name collisions in trash
  basename=$(basename "$file")
  timestamp=$(date +%Y%m%d_%H%M%S)
  mv "$file" "$TRASH/${basename}_${timestamp}"
  echo "Moved to trash: $file"
done

echo ""
echo "Trash is at: $TRASH"
echo "To permanently delete: rm -rf $TRASH/*"
