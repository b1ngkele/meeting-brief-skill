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
    "公司级-会议内容": (
        Path("skills/meeting-brief-skill/assets/公司级.docx"),
        "一、会议内容",
        "二、会议要求",
    ),
    "公司级-会议要求": (
        Path("skills/meeting-brief-skill/assets/公司级.docx"),
        "二、会议要求",
        "督办",
    ),
    "飞机端-会议重点内容": (
        Path("skills/meeting-brief-skill/assets/飞机端.docx"),
        "会议重点内容",
        "参会领导作工作指示",
    ),
    "飞机端-参会领导指示": (
        Path("skills/meeting-brief-skill/assets/飞机端.docx"),
        "参会领导作工作指示",
        "承办部门：",
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
  mkdir -p "$TMP_DIR/维修" "$TMP_DIR/数科" "$TMP_DIR/公司级" "$TMP_DIR/飞机端"

  cat >"$TMP_DIR/maintenance.md" <<'EOF'
## 自检事项
1. 自检结论：维修模板可正常替换会议重点讨论事项正文。
EOF

  cat >"$TMP_DIR/digital.md" <<'EOF'
## 自检事项
1. 自检结论：数科模板可正常替换参会领导工作指示正文。
EOF

  cat >"$TMP_DIR/company.md" <<'EOF'
# 会议内容
本次会议围绕公司级会议纪要模板替换能力开展自检，确认会议内容区块可独立生成和写入。

# 会议要求
会议要求持续保持模板结构稳定，确保会议要求区块可独立生成和写入。

## 自检要求
请保持督办、出席人员、主送和承办部门等模板原有内容不变。
EOF

  cat >"$TMP_DIR/aircraft.md" <<'EOF'
# 会议重点内容
## O1生产主线
### 五月工作进展及成果
围绕飞机端工作汇报模板替换能力开展自检，确认会议重点内容区块可独立生成和写入。

### 六月工作计划
后续持续保持模板结构稳定，确保楷体标题和仿宋正文格式被继承。

# 参会领导作工作指示
会议要求继续保持模板替换边界清晰，确保参会领导作工作指示区块可独立生成和写入。
EOF

  "$ROOT_DIR/tools/build_meeting_brief.sh" "$TMP_DIR/maintenance.md" "$TMP_DIR/维修" 维修 >/dev/null
  "$ROOT_DIR/tools/build_meeting_brief.sh" "$TMP_DIR/digital.md" "$TMP_DIR/数科" 数科 >/dev/null
  "$ROOT_DIR/tools/build_meeting_brief.sh" "$TMP_DIR/company.md" "$TMP_DIR/公司级" 公司级 >/dev/null
  "$ROOT_DIR/tools/build_meeting_brief.sh" "$TMP_DIR/aircraft.md" "$TMP_DIR/飞机端" 飞机端 >/dev/null

  check_file "$TMP_DIR/维修/会议简报.docx"
  check_file "$TMP_DIR/数科/会议简报.docx"
  check_file "$TMP_DIR/公司级/会议简报.docx"
  check_file "$TMP_DIR/飞机端/会议简报.docx"
  pass "All template profiles generated DOCX files"
}

check_file "$ROOT_DIR/requirements.txt"
check_file "$ROOT_DIR/tools/build_meeting_brief.sh"
check_file "$SKILL_DIR/scripts/replace_meeting_section.py"
check_file "$SKILL_DIR/scripts/replace_company_meeting_sections.py"
check_file "$SKILL_DIR/scripts/replace_aircraft_meeting_sections.py"
check_file "$SKILL_DIR/scripts/extract_pdf_text.py"
check_file "$SKILL_DIR/scripts/extract_pptx_text.py"
check_python
check_template_markers
check_profile_builds

printf '\nSelf-check passed.\n'
