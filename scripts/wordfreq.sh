#!/bin/bash
# wordfreq.sh — top N most frequent words in a file
# Usage: ./wordfreq.sh [file] [top_n]

file="${1:-/dev/stdin}"
top="${2:-20}"

cat "$file" \
  | tr -s '[:space:][:punct:]' '\n' \
  | tr '[:upper:]' '[:lower:]' \
  | grep -v '^$' \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -"$top"
