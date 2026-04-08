---
name: wiki
description: "Persistent topic-centered research skill for Codex. Trigger on any explicit $wiki intent to start, resume, pause, summarize, restart, reference material, or save-turn/st for a topic, while writing directly to wiki/english-topic-slug state files."
---

# Wiki Topic Research

## Iron Law
Never treat chat history as memory; always read and update the topic files under `wiki/<topic>/` before claiming a research session has been resumed, paused, or summarized.

## Workflow Checklist

- [ ] Parse the `$wiki` intent, normalize the topic to an English kebab-case slug, and verify if the topic already exists.
- [ ] Load `references/file-contracts.md` to understand expectations before creating or editing topic files.
- [ ] Read or bootstrap `wiki/<topic>/` so `plan.md`, `research-log.md`, `highlights.md`, `sources.md`, and a `chat/` directory are present.
- [ ] Review current `plan.md`, the latest `chat/YYYY-MM-DD-*.md` when relevant, and the recent tail of `research-log.md` to establish the in-flight narrative.
- [ ] Read `plan.md` as the topic-local research board; keep it in `Todo / Doing / Done / Blocked` top-level sections, and prefer `### <task>` subheadings inside each section when recording structured work.
- [ ] If the user provides an existing article, note set, or draft, record its original path or URL in `sources.md`, summarize the relevant takeaways into `research-log.md`, and only promote stable conclusions into `highlights.md`.
- [ ] Run work in research mode: append one typed entry to `research-log.md`, update `highlights.md` only when the conclusions are durable, and update `plan.md` if the task board moved.
- [ ] Treat `chat/*.md` as explicit excerpts, not automatic transcripts. Only write to it when the user says `$wiki save-turn` or `$wiki st`; then save the immediately previous user turn and agent turn into the active chat file.
- [ ] Sync metadata with `references/session-workflow.md`, especially when the user requests `pause`, `summary`, `stop`, or `restart` so the appropriate compression and next-step updates are executed.
- [ ] Before responding, load `references/verification-playbook.md` if a verification prompt appears or if the user asks about how the workflow behaves.
- [ ] On exit (pause/summary/stop), compress the current state into `research-log.md`, `plan.md`, and `highlights.md` as needed. Do not force chat writes unless the user explicitly asked to save a turn.

## Progressive Loading

- Load only the reference file you need: bring in `file-contracts.md` when touching files, `session-workflow.md` during flow transitions, and `verification-playbook.md` when verifying behavior or answering meta-questions.
- Keep topic updates localized to `wiki/<topic>/`; do not open or write to other directories while the workflow is running.

## Anti-patterns

- Do not paste raw chat transcripts into topic files.
- Do not auto-save every turn into `chat/*.md`; only `$wiki save-turn` / `$wiki st` may write turn excerpts there.
- Do not edit `highlights.md` or `sources.md` on every minor turn—update them only at clear milestone moments.
- Do not use `chat/*.md` as a task board; keep ongoing research tasks in `plan.md`.
- Do not use a non-English or unstable directory name for `wiki/<topic>/`; keep the slug ASCII and stable, and keep human-readable labels inside the files.
- Do not update `wiki/<topic>/` without first reading its persisted state.
- Do not resume or summarize a topic if you have not consulted the existing `plan.md`, recent `research-log.md`, and latest relevant chat file.
- Do not write outside of `wiki/<topic>/` during the research workflow.
