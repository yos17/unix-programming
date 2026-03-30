#!/bin/bash
# wordfreq.sh — show word frequency in a file
# Usage: ./wordfreq.sh [file] [top_n]
# Example: ./wordfreq.sh essay.txt 20

file="${1:-/dev/stdin}"
top="${2:-20}"

cat "$file" \
  | tr -s '[:space:]' '\n' \
  | tr -d '[:punct:]' \
  | tr '[:upper:]' '[:lower:]' \
  | grep -v '^$' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -"$top"
