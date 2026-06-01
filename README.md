# 会议简报生成工作区

这个工作区用于反复生成会议简报。日常使用时，只需要替换本次会议的输入文件，不需要改模板或脚本。

## 推荐目录

```text
input/current/
  notes.txt          # 本次会议手写笔记
  transcript.txt     # 本次会议录音转写
  weeklyMeetingMaterials.pdf  # （可选）周例会材料 PDF

templates/
  模版.docx          # 原始会议简报模板，尽量不要改
  长龙数科领导班子工作例会模板.docx # 领导班子例会正式样式参考

skills/
  meeting-brief-skill/   # skill 源码备份
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
  start_new_meeting.sh   # 归档旧输入，准备下一次会议
```

## 每次工作方式

1. 把新的 `notes.txt` 和 `transcript.txt` 放到 `input/current/`，覆盖旧文件。如果有周例会材料 PDF，同时放入 `weeklyMeetingMaterials.pdf`。
2. 让 Codex 使用 `$meeting-brief` 读取这两个文件，生成 `会议重点讨论事项.md`。
   - Skill 会自动读取 `resources/` 下的术语词典、人名映射等资源来提升生成质量。
   - 生成完成后，Skill 会自动将新发现的民航术语和人名追加到资源文件中。
3. 运行 `tools/build_meeting_brief.sh`，生成最终 DOCX。
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

如果是“长龙数科领导班子工作例会”，优先使用 `templates/长龙数科领导班子工作例会模板.docx`，替换区间为 `五、参会领导作工作指示` 到 `六、督办工作`。

## 注意

- 不要在根目录直接堆放每次生成的 DOCX。
- 不要改 `templates/模版.docx`，除非要永久调整会议简报版式。
- `$meeting-brief` 只替换模板中的“会议重点讨论事项”正文区，模板标题和承办部门段落会保留。
