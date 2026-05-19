# Session Workflow

## start
1. Normalize the topic to an English kebab-case slug and determine if `wiki/<topic>/` exists.
2. Bootstrap the topic folder if missing (per `file-contracts.md`).
3. Read `plan.md`, recent `research-log.md` entries, `highlights.md`, and the most relevant recent chat excerpt to understand what is already saved.
4. Do not create a chat file by default. Reserve `chat/*.md` for explicit `$wiki save-turn` / `$wiki st` excerpts.

## reference existing material
1. Preserve the original material in place; do not copy it into `wiki/<topic>/` by default.
2. Add a source record to `sources.md` with the original path or URL plus a note on relevance.
3. Append a `research-log.md` entry explaining what was extracted from the material.
4. Only after the source is recorded, summarize stable conclusions into `highlights.md` when justified.
5. If the referenced material creates obvious follow-up work, add those items to `plan.md`.

## resume
1. Read `plan.md` to see the current `Doing` and `Blocked` work.
2. Read the newest entries from `research-log.md` to recover the latest reasoning trail.
3. Review `highlights.md` to recover durable conclusions before doing fresh research.
4. Load the latest chat file only if it matters for the current request.
5. Continue the research turn with a new `research-log.md` entry and update `plan.md` if the board changed.

## save-turn / st
1. Identify the immediately previous user turn and the immediately previous agent turn.
2. If there is no active chat file for the topic, create `chat/YYYY-MM-DD-<auto-slug>.md` with the required file-level metadata.
3. Append one excerpt block using an auto-written `## <title>` followed by `### User` and `### Agent` sections.
4. Wrap both bodies in fenced `text` code blocks.
5. Do not add turn-level timestamps or trigger metadata.

## pause / summary / stop
1. Compress the active state into `research-log.md`, noting any outstanding open questions and immediate next steps.
2. Update `plan.md` if items moved into `Done` or `Blocked`, and prefer turning completed work into `### <task>` blocks instead of appending a long flat list.
3. Export durable conclusions into `highlights.md` when justified, and update `sources.md` only when the source set changed.
4. Do not force a chat write.
