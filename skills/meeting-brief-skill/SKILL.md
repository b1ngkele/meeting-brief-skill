---
name: meeting-brief
description: Generate a Chinese meeting brief from handwritten notes and transcript text, using a fixed DOCX template and replacing only the "会议重点讨论事项" section while preserving the template title, heading, spacing, and footer formatting.
---

# Meeting Brief

Use this skill when the user wants to generate or update a meeting brief from `notes.txt`, `transcript.txt`, or similar meeting materials, especially when the output must keep the existing Word template layout.

## Workflow

1. Read the user's notes and transcript.
2. Draft only the replacement content for the section after `会议重点讨论事项`.
3. Keep the brief concise, formal, and action-oriented:
   - Use short topic headings for major agenda items.
   - Under each heading, use one or more compact paragraphs.
   - Preserve dates, responsible people, deadlines, risks, and decisions from the source material.
   - Prefer facts confirmed by both notes and transcript; when they conflict, use the notes as the stronger signal and mention uncertainty only if important.
4. Save the replacement section as a UTF-8 markdown text file.
5. Run `scripts/replace_meeting_section.py` with the bundled template unless the user supplied another template.
6. Verify the generated DOCX structurally, and render it for visual QA when the Documents skill renderer is available.

## Replacement Content Format

The content file must contain only the body that comes after `会议重点讨论事项`.

Use:

```markdown
## 工卡系统建设与切换规划
1. 工卡管理系统进展：3月31日已完成联调和首轮业务测试，系统具备基本管理能力，后续28项优化计划于4月16日完成。
2. 系统切换计划：生产要素评估模块计划于4月16日完成，维管一期新工卡后续切换至新模块。

## 工时报钟
已完成8453号飞机C检试点，未发现阻断性缺陷。四月份建议扩大试点范围。
```

Rules:

- `## 标题` becomes a subsection heading, copied from the template's subsection style: 楷体、加粗、固定行距、原缩进。
- Normal lines become body paragraphs, copied from the template body style: 仿宋、固定行距、原缩进。
- Lines matching `1. 标题：正文` are written as body paragraphs with the label through `：` bolded.
- Do not include the main heading `会议重点讨论事项`; the script preserves the existing template paragraph.

## Command

```bash
python scripts/replace_meeting_section.py \
  --template assets/template.docx \
  --content replacement.md \
  --output meeting-brief.docx
```

Optional flags:

- `--section-heading` defaults to `会议重点讨论事项`.
- `--end-marker` defaults to `承办部门：`.

## Quality Checks

- Confirm the document still contains one `会议重点讨论事项` heading.
- Confirm old section paragraphs were removed and the footer paragraph beginning with `承办部门：` remains.
- If generating a final DOCX for the user, render and inspect page PNGs using the Documents skill when possible.
