# 会议简报生成工作区

这个工作区用于反复生成会议简报。日常使用时，只需要替换本次会议的输入文件，不需要改模板或脚本。

## 推荐目录

```text
requirements.txt          # Python 依赖清单

input/current/
  notes.txt          # 本次会议手写笔记
  transcript.txt     # 本次会议录音转写
  weeklyMeetingMaterials.pdf  # （可选）周例会材料 PDF

skills/
  meeting-brief-skill/   # skill 源码备份
    assets/               # 唯一模板源
      维修.docx           # 维修专班会议简报模板，替换“会议重点讨论事项”正文
      数科.docx           # 数科领导班子例会模板，替换“五、参会领导作工作指示”正文
    resources/            # 渐进式积累的民航领域知识资源
      terminology.md      # 民航术语纠错词典（每次会议自动更新）
      people_roles.md     # 参会人员与角色映射
      org_context.md      # 组织背景与业务架构
      writing_style.md    # 写作风格偏好与用户反馈

output/
  20260528-161600/       # 每次生成一个独立目录
    会议重点讨论事项.md
    会议简报.docx

tools/
  build_meeting_brief.sh # 把正文稿写入模板
  self_check.sh          # 检查依赖、模板锚点和两类 DOCX 生成
  start_new_meeting.sh   # 归档旧输入，准备下一次会议
```

## 每次工作方式

1. 把新的 `notes.txt` 和 `transcript.txt` 放到 `input/current/`，覆盖旧文件。如果有周例会材料 PDF，同时放入 `weeklyMeetingMaterials.pdf`。
2. 让 Codex 使用 `$meeting-brief` 读取这两个文件，生成 `会议重点讨论事项.md`。
   - Skill 会自动读取 `resources/` 下的术语词典、人名映射等资源来提升生成质量。
   - 生成完成后，Skill 会自动将新发现的民航术语和人名追加到资源文件中。
3. 运行 `tools/build_meeting_brief.sh <replacement.md> [output_dir] [模板类型]`，生成最终 DOCX。
4. 检查 `output/时间戳/会议简报.docx`。
5. （可选）审阅 `resources/` 下新增的 `⚠️待确认` 条目，将确认正确的改为 `✅已确认`。
6. 如果要保留本次原始输入，可把 `input/current/` 复制到 `input/archive/会议日期或主题/`。

开始下一场会议前，可以运行：

```bash
tools/start_new_meeting.sh 2026-03-31-维修专班周例会
```

它会把当前 `input/current/` 里的文件移动到 `input/archive/2026-03-31-维修专班周例会/`，然后你再放入新的 `notes.txt` 和 `transcript.txt`。

## 给 Codex 的常用指令

```text
Use $meeting-brief 根据 input/current/ 下的输入文件（notes.txt、transcript.txt、以及可选的 weeklyMeetingMaterials.pdf）生成会议简报，输出到 output/新的时间戳目录。
```

模板类型：

- `维修`：默认值，使用 `skills/meeting-brief-skill/assets/维修.docx`，替换 `会议重点讨论事项` 到 `承办部门：` 之间的正文。
- `数科`：使用 `skills/meeting-brief-skill/assets/数科.docx`，替换 `五、参会领导作工作指示` 到 `六、督办工作` 之间的正文。

## 注意

- 不要在根目录直接堆放每次生成的 DOCX。
- 不要改 `skills/meeting-brief-skill/assets/维修.docx` 和 `skills/meeting-brief-skill/assets/数科.docx`，除非要永久调整会议简报版式。
- `$meeting-brief` 只替换所选模板配置的正文区，模板标题、章节标题和后续段落会保留。

## 跨机器运行

`tools/build_meeting_brief.sh` 默认使用当前机器 PATH 里的 `python3`，并调用本工作区内的 `skills/meeting-brief-skill/scripts/replace_meeting_section.py`，不依赖某台电脑上的 Codex 缓存目录。

首次使用前，在目标机器安装 Python 依赖：

```bash
python3 -m pip install -r requirements.txt
```

安装后建议先运行自检：

```bash
tools/self_check.sh
```

常用命令：

```bash
tools/build_meeting_brief.sh output/20260528-161600/会议重点讨论事项.md
tools/build_meeting_brief.sh output/20260528-173203/会议重点讨论事项_领导班子版.md output/数科简报 数科
```

如需覆盖默认路径，可使用环境变量：

```bash
PYTHON=/path/to/python3 \
MEETING_TEMPLATE_TYPE=数科 \
MEETING_TEMPLATE=/path/to/template.docx \
tools/build_meeting_brief.sh output/20260528-161600/会议重点讨论事项.md
```
