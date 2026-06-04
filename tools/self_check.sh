#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3}"
SKILL_DIR="${MEETING_BRIEF_SKILL_DIR:-$ROOT_DIR/skills/meeting-brief-skill}"
TMP_DIR="${TMPDIR:-/tmp}/meeting-brief-self-check"

cd "$ROOT_DIR"
export PYTHON
export MEETING_BRIEF_SKILL_DIR="$SKILL_DIR"

pass() {
  printf '✓ %s\n' "$1"
}

fail() {
  printf '✗ %s\n' "$1" >&2
  exit 1
}

check_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "Missing file: $path"
  pass "Found $path"
}

check_python() {
  command -v "$PYTHON" >/dev/null 2>&1 || fail "Python executable not found: $PYTHON"
  "$PYTHON" - <<'PY'
import importlib.util
import sys

missing = [
    module
    for module in ("docx", "pdfplumber")
    if importlib.util.find_spec(module) is None
]
if missing:
    print(
        "Missing Python modules: "
        + ", ".join(missing)
        + "\nInstall with: python3 -m pip install -r requirements.txt",
        file=sys.stderr,
    )
    raise SystemExit(1)
PY
  pass "Python dependencies are available"
}

check_template_markers() {
  "$PYTHON" - <<'PY'
from pathlib import Path
from docx import Document

profiles = {
    "维修": (
        Path("skills/meeting-brief-skill/assets/维修.docx"),
        "会议重点讨论事项",
        "承办部门：",
    ),
    "数科": (
        Path("skills/meeting-brief-skill/assets/数科.docx"),
        "五、参会领导作工作指示",
        "六、督办工作",
    ),
}

for name, (path, start_marker, end_marker) in profiles.items():
    if not path.exists():
        raise SystemExit(f"Missing template for {name}: {path}")
    texts = [paragraph.text.strip() for paragraph in Document(path).paragraphs]
    if start_marker not in texts:
        raise SystemExit(f"{name} template missing start marker: {start_marker}")
    start_index = texts.index(start_marker)
    if not any(text.startswith(end_marker) for text in texts[start_index + 1 :]):
        raise SystemExit(f"{name} template missing end marker after start: {end_marker}")
PY
  pass "Template markers are valid"
}

check_profile_builds() {
  rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR/维修" "$TMP_DIR/数科"

  cat >"$TMP_DIR/maintenance.md" <<'EOF'
## 自检事项
1. 自检结论：维修模板可正常替换会议重点讨论事项正文。
EOF

  cat >"$TMP_DIR/digital.md" <<'EOF'
## 自检事项
1. 自检结论：数科模板可正常替换参会领导工作指示正文。
EOF

  "$ROOT_DIR/tools/build_meeting_brief.sh" "$TMP_DIR/maintenance.md" "$TMP_DIR/维修" 维修 >/dev/null
  "$ROOT_DIR/tools/build_meeting_brief.sh" "$TMP_DIR/digital.md" "$TMP_DIR/数科" 数科 >/dev/null

  check_file "$TMP_DIR/维修/会议简报.docx"
  check_file "$TMP_DIR/数科/会议简报.docx"
  pass "Both template profiles generated DOCX files"
}

check_file "$ROOT_DIR/requirements.txt"
check_file "$ROOT_DIR/tools/build_meeting_brief.sh"
check_file "$SKILL_DIR/scripts/replace_meeting_section.py"
check_file "$SKILL_DIR/scripts/extract_pdf_text.py"
check_python
check_template_markers
check_profile_builds

printf '\nSelf-check passed.\n'
