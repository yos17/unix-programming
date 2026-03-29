#!/bin/bash
# bigfiles.sh — find files larger than N megabytes
# Usage: ./bigfiles.sh [size_in_MB] [directory]

limit="${1:-100}"
dir="${2:-.}"

echo "Files larger than ${limit}MB in $dir:"
echo ""

find "$dir" -type f -size "+${limit}M" 2>/dev/null | while read -r file; do
  size=$(du -sh "$file" 2>/dev/null | cut -f1)
  echo "$size  $file"
done | sort -rh
