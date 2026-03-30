#!/bin/bash
# log-summary.sh — summarize a log file
# Usage: ./log-summary.sh [logfile]
#        cat logfile | ./log-summary.sh

set -euo pipefail

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: log-summary.sh [logfile]"
  echo "Counts errors, warnings, and info messages in a log file"
  exit 0
fi

input="${1:-/dev/stdin}"

errors=$(grep -ci 'error'   "$input" 2>/dev/null || echo 0)
warnings=$(grep -ci 'warning' "$input" 2>/dev/null || echo 0)
info=$(grep -ci 'info'    "$input" 2>/dev/null || echo 0)

echo "=== Log Summary ==="
echo "Errors:   $errors"
echo "Warnings: $warnings"
echo "Info:     $info"
echo ""
echo "=== Last 5 Errors ==="
grep -i 'error' "$input" 2>/dev/null | tail -5 || echo "(none)"
