# Verification Playbook

## Prompt Suite
- 用 $wiki 研究 lsm tree write path
- 用 $wiki 继续上次的 lsm tree
- 用 $wiki 总结我当前对 lsm tree 的研究进度
- 用 $wiki 暂停当前 lsm tree 研究
- 用 $wiki 重新开始 raft log replication
- 用 $wiki 把 blog 里的宏观经济学史学习笔记作为当前 topic 的参考材料
- 用 $wiki save-turn 保存上一轮
- 用 $wiki st 保存上一轮

## Expected Effects
- Trigger on explicit `$wiki` prompts and only operate within `wiki/<english-topic-slug>/`.
- `plan.md`, `research-log.md`, and `highlights.md` are read before building a response for resume-style prompts.
- `plan.md` uses `Todo / Doing / Done / Blocked` as top-level sections, and meaningful work in `Doing` / `Done` should be organized with `### <task>` subheadings when structure is needed.
- `chat/YYYY-MM-DD-<auto-slug>.md` is created only for explicit `save-turn` / `st` flows, or auto-created on the first save-turn if missing.
- Pause or summary flows compress the current state into `research-log.md`, update `plan.md`, and promote durable conclusions into `highlights.md` when justified.
- Pre-existing material is referenced from its original path or URL via `sources.md` instead of being copied into the topic directory by default.
- Saved chat excerpts use file metadata keys `date`, `title`, `slug`, `status`, and each excerpt block uses `## <auto-title>` with `### User` / `### Agent` plus fenced `text` blocks.
