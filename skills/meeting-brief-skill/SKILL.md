---
name: meeting-brief
description: Generate a Chinese meeting brief from handwritten notes, transcript text, and optional weekly meeting materials (PDF), using the matching DOCX template for 维修 or 数科 meetings while preserving template layout and replacing only the configured section body.
---

# Meeting Brief

Use this skill when the user wants to generate or update a meeting brief from `notes.txt`, `transcript.txt`, and optionally `weeklyMeetingMaterials.pdf`, especially when the output must keep the existing Word template layout.

## Domain Context

This skill operates in the **civil aviation industry**. Meeting briefs are generated for 长龙航空's IT subsidiary (长龙数科). Discussions typically involve airline operations, aircraft maintenance, flight crew management, passenger services, and IT platform development.

Before generating any content, read `resources/org_context.md` for organization structure, business architecture (the "云" system), and key projects. This context helps correctly interpret ambiguous references in notes and transcripts.

## Workflow

0. **Check for optional PDF meeting materials**: Look for `weeklyMeetingMaterials.pdf` in the input directory (`input/current/`).
   - If the file exists, run the PDF extraction script to convert it to markdown:
     ```bash
     python scripts/extract_pdf_text.py input/current/weeklyMeetingMaterials.pdf
     ```
     This produces `input/current/weeklyMeetingMaterials.md`.
   - If the file does not exist, skip this step and proceed without PDF reference material.
1. Read the user's notes and transcript. If `weeklyMeetingMaterials.md` was generated in step 0, also read it as **background reference material** — use it to better understand the agenda topics, verify terminology, and fill in context gaps, but do not copy its content verbatim into the brief.
2. **Load domain resources**: Read all files under `resources/` to load:
   - `resources/terminology.md` — known civil aviation term corrections for transcript errors.
   - `resources/people_roles.md` — name/nickname → formal name and role mappings.
   - `resources/org_context.md` — organization structure, cloud/platform architecture, key projects.
   - `resources/writing_style.md` — accumulated writing style preferences and user feedback.
3. Choose the correct template profile:
   - **维修**: use `assets/维修.docx`; replace the body after `会议重点讨论事项` and before the paragraph beginning `承办部门：`.
   - **数科**: use `assets/数科.docx`; replace only the body between `五、参会领导作工作指示` and `六、督办工作`.
4. Draft only the replacement content for the chosen section.
5. Keep the brief concise, formal, and action-oriented:
   - Use short topic headings for major agenda items.
   - Under each heading, use one or more compact paragraphs.
   - Preserve dates, responsible people, deadlines, risks, and decisions from the source material.
   - Prefer facts confirmed by both notes and transcript; when they conflict, use the notes as the stronger signal and mention uncertainty only if important.
   - **Terminology correction**: Cross-reference transcript text against `resources/terminology.md` to correct misrecognized aviation terms. Use the correct term in the output even when the transcript uses a wrong or colloquial form.
   - **Name resolution**: Resolve nicknames and informal references (e.g. "老胡") to formal names (e.g. "胡洪杰") using `resources/people_roles.md`. In the brief output, always use the formal name.
   - **Style alignment**: Follow any additional preferences recorded in `resources/writing_style.md`.
6. Save the replacement section as a UTF-8 markdown text file.
7. Run `scripts/replace_meeting_section.py` with the selected template.
8. Verify the generated DOCX structurally, and render it for visual QA when the Documents skill renderer is available.
9. **Update resources**: After generating the brief, scan the source material and output for:
   - Civil aviation terms not yet in `resources/terminology.md` — append with `⚠️待确认` status.
   - Person names or roles not yet in `resources/people_roles.md` — append with `⚠️待确认` status.
   - Organization or project details not yet in `resources/org_context.md` — append with `⚠️待确认` status.
   - Report all new additions to the user in the response so they can review and correct if needed.

## Leadership-Team Brief Style

For `长龙数科领导班子工作例会`, match the reference style:

- Preserve header metadata such as issue number, company name, meeting time/place/host, participants, absent participants, `五、参会领导作工作指示`, `六、督办工作`, and the undertaking department.
- Use `## 督办回顾` for short progress-review paragraphs.
- Use `## 各部门重点事项及领导工作指示` for the main decisions and instructions.
- Prefer fewer, broader items over many narrow headings. The brief should read like leadership instructions, not a project-by-project status digest.
- Use numbered paragraphs for major instructions, e.g. `1. 2027年外部收入考核与内部改革工作部署：...`.
- Keep wording decisive: `会议要求`、`请...牵头`、`需...完成`、`后续...推进`.
- Move minor schedule items such as团建 or评定 into `## 其他事项` only when they need to be retained.

## Replacement Content Format

The content file must contain only the replacement body for the selected profile.

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
- Do not include the profile's start heading (`会议重点讨论事项` or `五、参会领导作工作指示`); the script preserves the existing template paragraph.

## Command

```bash
python scripts/replace_meeting_section.py \
  --template assets/维修.docx \
  --content replacement.md \
  --output meeting-brief.docx
```

Optional flags:

- `--section-heading` defaults to `会议重点讨论事项`.
- `--end-marker` defaults to `承办部门：`.
- For the 数科 template, pass `--template assets/数科.docx --section-heading 五、参会领导作工作指示 --end-marker 六、督办工作`.

## Resource Files

The skill maintains a set of progressively-built knowledge resources under `resources/`:

| File | Purpose | Update Frequency |
|------|---------|------------------|
| `terminology.md` | Civil aviation term corrections for transcript ASR errors | Every session |
| `people_roles.md` | Nickname → formal name and role mappings | Every session |
| `org_context.md` | Organization structure, cloud architecture, key projects | Occasionally |
| `writing_style.md` | Writing conventions and user feedback log | On user feedback |

### Status Annotations

Every entry uses one of these statuses:

- `✅已确认` — reviewed and confirmed by the user; use with confidence.
- `⚠️待确认` — AI-identified, not yet reviewed; use as best-effort reference.
- `❌已废弃` — marked incorrect by the user; do not use.

When generating a brief, prefer `✅已确认` entries. Use `⚠️待确认` entries as guidance but exercise caution. Ignore `❌已废弃` entries.

### User Maintenance

The user may directly edit any resource file at any time to correct, confirm, or remove entries. The AI should respect user edits in subsequent sessions.

## Optional Input Files

| File | Location | Purpose |
|------|----------|----------|
| `weeklyMeetingMaterials.pdf` | `input/current/` | 周例会材料 PPT 导出的 PDF，包含议题清单和表格。不是每次会议都有。当存在时，作为背景参考帮助 AI 更准确地理解笔记和录音转写中的议题上下文。 |

### PDF Processing

- The skill uses `scripts/extract_pdf_text.py` (backed by `pdfplumber`) to convert PDF to markdown.
- Tables in the PDF are converted to markdown table format for better AI comprehension.
- The generated `.md` file is placed alongside the original PDF in `input/current/`.
- The `.md` file is a temporary intermediate artifact; the canonical source remains the original PDF.

## Quality Checks

- Confirm the document still contains one `会议重点讨论事项` heading.
- Confirm old section paragraphs were removed and the footer paragraph beginning with `承办部门：` remains.
- If generating a final DOCX for the user, render and inspect page PNGs using the Documents skill when possible.
