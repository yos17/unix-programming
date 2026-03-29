#!/bin/bash
# backup.sh — backup a directory with a timestamp
# Usage: ./backup.sh source destination

if [ $# -ne 2 ]; then
  echo "Usage: $0 source destination" >&2
  exit 1
fi

source="$1"
dest="$2"
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
backup_name="backup_${timestamp}"

if [ ! -d "$source" ]; then
  echo "Error: $source is not a directory" >&2
  exit 1
fi

mkdir -p "$dest"
cp -r "$source" "$dest/$backup_name"

if [ $? -eq 0 ]; then
  echo "✅ Backup created: $dest/$backup_name"
else
  echo "❌ Backup failed" >&2
  exit 1
fi
