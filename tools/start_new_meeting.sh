#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURRENT_DIR="$ROOT_DIR/input/current"
ARCHIVE_ROOT="$ROOT_DIR/input/archive"
LABEL="${1:-$(date +%Y%m%d-%H%M%S)}"
ARCHIVE_DIR="$ARCHIVE_ROOT/$LABEL"

mkdir -p "$CURRENT_DIR" "$ARCHIVE_DIR"

shopt -s nullglob
files=("$CURRENT_DIR"/*)

if (( ${#files[@]} == 0 )); then
  echo "No current input files to archive."
  echo "$CURRENT_DIR"
  exit 0
fi

for file in "${files[@]}"; do
  mv "$file" "$ARCHIVE_DIR/"
done

echo "Archived current input files to: $ARCHIVE_DIR"
echo "Put the next notes.txt, transcript.txt, and optionally weeklyMeetingMaterials.pdf or weeklyMeetingMaterials.pptx in: $CURRENT_DIR"
