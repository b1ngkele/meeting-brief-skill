#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3}"
SKILL_DIR="${MEETING_BRIEF_SKILL_DIR:-$ROOT_DIR/skills/meeting-brief-skill}"
REPLACE_SCRIPT="${MEETING_REPLACE_SCRIPT:-$SKILL_DIR/scripts/replace_meeting_section.py}"
TEMPLATE_TYPE="${MEETING_TEMPLATE_TYPE:-${3:-维修}}"
OUTPUT_NAME="${OUTPUT_NAME:-会议简报.docx}"

CONTENT="${1:-}"
OUT_DIR="${2:-}"

case "$TEMPLATE_TYPE" in
  维修|weixiu|maintenance|repair)
    DEFAULT_TEMPLATE="$SKILL_DIR/assets/维修.docx"
    DEFAULT_SECTION_HEADING="会议重点讨论事项"
    DEFAULT_END_MARKER="承办部门："
    CONTENT_BASENAME="会议重点讨论事项.md"
    ;;
  数科|shuke|leadership|digital)
    DEFAULT_TEMPLATE="$SKILL_DIR/assets/数科.docx"
    DEFAULT_SECTION_HEADING="五、参会领导作工作指示"
    DEFAULT_END_MARKER="六、督办工作"
    CONTENT_BASENAME="参会领导工作指示.md"
    ;;
  *)
    echo "Unknown template type: $TEMPLATE_TYPE" >&2
    echo "Use one of: 维修, 数科, maintenance, leadership." >&2
    exit 2
    ;;
esac

TEMPLATE="${MEETING_TEMPLATE:-$DEFAULT_TEMPLATE}"
SECTION_HEADING="${SECTION_HEADING:-$DEFAULT_SECTION_HEADING}"
END_MARKER="${END_MARKER:-$DEFAULT_END_MARKER}"

if [[ -z "$CONTENT" ]]; then
  echo "Usage: tools/build_meeting_brief.sh <replacement.md> [output_dir] [template_type]" >&2
  echo "template_type: 维修 (default) or 数科" >&2
  exit 2
fi

if [[ ! -f "$CONTENT" ]]; then
  echo "Content file not found: $CONTENT" >&2
  exit 2
fi

if ! command -v "$PYTHON" >/dev/null 2>&1; then
  echo "Python executable not found: $PYTHON" >&2
  echo "Install Python 3 or set PYTHON=/path/to/python3." >&2
  exit 2
fi

if [[ ! -f "$REPLACE_SCRIPT" ]]; then
  echo "Replacement script not found: $REPLACE_SCRIPT" >&2
  echo "Set MEETING_BRIEF_SKILL_DIR or MEETING_REPLACE_SCRIPT if your skill is installed elsewhere." >&2
  exit 2
fi

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Template not found: $TEMPLATE" >&2
  echo "Set MEETING_TEMPLATE=/path/to/template.docx." >&2
  exit 2
fi

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$ROOT_DIR/output/$(date +%Y%m%d-%H%M%S)"
fi

mkdir -p "$OUT_DIR"
CONTENT_COPY="$OUT_DIR/$CONTENT_BASENAME"
if [[ ! -e "$CONTENT_COPY" || ! "$CONTENT" -ef "$CONTENT_COPY" ]]; then
  cp "$CONTENT" "$CONTENT_COPY"
fi

"$PYTHON" "$REPLACE_SCRIPT" \
  --template "$TEMPLATE" \
  --content "$CONTENT_COPY" \
  --output "$OUT_DIR/$OUTPUT_NAME" \
  --section-heading "$SECTION_HEADING" \
  --end-marker "$END_MARKER"

echo "$OUT_DIR/$OUTPUT_NAME"
