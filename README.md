# 会议简报生成工作区

这个工作区用于反复生成会议简报。日常使用时，只需要替换本次会议的输入文件，不需要改模板或脚本。

## 推荐目录

```text
input/current/
  notes.txt          # 本次会议手写笔记
  transcript.txt     # 本次会议录音转写

templates/
  模版.docx          # 原始会议简报模板，尽量不要改

skills/
  meeting-brief-skill/   # skill 源码备份

output/
  20260528-161600/       # 每次生成一个独立目录
    会议重点讨论事项.md
    会议简报.docx

tools/
  build_meeting_brief.sh # 把正文稿写入模板
  start_new_meeting.sh   # 归档旧输入，准备下一次会议
```

## 每次工作方式

1. 把新的 `notes.txt` 和 `transcript.txt` 放到 `input/current/`，覆盖旧文件。
2. 让 Codex 使用 `$meeting-brief` 读取这两个文件，生成 `会议重点讨论事项.md`。
3. 运行 `tools/build_meeting_brief.sh`，生成最终 DOCX。
4. 检查 `output/时间戳/会议简报.docx`。
5. 如果要保留本次原始输入，可把 `input/current/` 复制到 `input/archive/会议日期或主题/`。

开始下一场会议前，可以运行：

```bash
tools/start_new_meeting.sh 2026-03-31-维修专班周例会
```

它会把当前 `input/current/` 里的文件移动到 `input/archive/2026-03-31-维修专班周例会/`，然后你再放入新的 `notes.txt` 和 `transcript.txt`。

## 给 Codex 的常用指令

```text
Use $meeting-brief 根据 input/current/notes.txt 和 input/current/transcript.txt 生成会议简报，输出到 output/新的时间戳目录。
```

## 注意

- 不要在根目录直接堆放每次生成的 DOCX。
- 不要改 `templates/模版.docx`，除非要永久调整会议简报版式。
- `$meeting-brief` 只替换模板中的“会议重点讨论事项”正文区，模板标题和承办部门段落会保留。
