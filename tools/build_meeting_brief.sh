#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="/Users/shizu/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3"
REPLACE_SCRIPT="/Users/shizu/.codex/skills/meeting-brief/scripts/replace_meeting_section.py"
TEMPLATE="$ROOT_DIR/templates/模版.docx"

CONTENT="${1:-}"
OUT_DIR="${2:-}"

if [[ -z "$CONTENT" ]]; then
  echo "Usage: tools/build_meeting_brief.sh <会议重点讨论事项.md> [output_dir]" >&2
  exit 2
fi

if [[ ! -f "$CONTENT" ]]; then
  echo "Content file not found: $CONTENT" >&2
  exit 2
fi

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$ROOT_DIR/output/$(date +%Y%m%d-%H%M%S)"
fi

mkdir -p "$OUT_DIR"
if [[ "$CONTENT" != "$OUT_DIR/会议重点讨论事项.md" ]]; then
  cp "$CONTENT" "$OUT_DIR/会议重点讨论事项.md"
fi

"$PYTHON" "$REPLACE_SCRIPT" \
  --template "$TEMPLATE" \
  --content "$OUT_DIR/会议重点讨论事项.md" \
  --output "$OUT_DIR/会议简报.docx"

echo "$OUT_DIR/会议简报.docx"
