---
name: linear-note
description: Post explicit agent notes or final issue reviews to the current Linear issue. Use for /linear-note, linear-note latest/end, sending the latest response to Linear, final reviews, issue retrospectives, 收口, 复盘, or 刷入 Linear.
trigger_keywords:
  - /linear-note
  - linear-note
  - linear note
  - linear latest
  - linear end
  - linear finalize
  - final review
  - issue retrospective
  - 刷到 Linear
  - 发到 Linear
  - 写入 Linear
  - 收口
  - 复盘
allowed-tools:
  - Bash
  - Read
---

# Linear Note

Post one explicit note or final review to the Linear issue linked by the current branch.
Use the bundled script as a black-box publishing helper; do not recreate Linear API calls in prompts.

## Modes

- `latest` (default): post the selected latest response, decision, or user-provided note.
- `end`: post the final issue review/retrospective with git facts. For Claude Code, base the review on an exported session artifact when available.

## Workflow

1. Decide the mode from the user's wording:
   - Use `latest` for `/linear-note`, "刷到 Linear", "发到 Linear", "post latest", or an explicit note.
   - Use `end` for "finalize", "final review", "收口", "复盘", or issue retrospective.
2. Prepare the body before calling the script:
   - For `latest`, keep it short and factual. If the target body is ambiguous, ask what to post.
   - For `end`, write a review with execution flow, key decisions, implementation, verification, and open risks/follow-ups.
3. Pipe the body into `scripts/linear.nu`.

Codex example:

```nushell
'<body to post>' | nu --stdin ~/.codex/skills/linear-note/scripts/linear.nu latest --issue LUC-48 --agent codex
```

Claude Code example:

```nushell
'<final review body>' | nu --stdin ~/.claude/skills/linear-note/scripts/linear.nu end --issue LUC-48 --agent claude-code
```

Omit `--issue` only when the current git branch or jj bookmark contains exactly one `LUC-123` key.

## Claude Code Session Review

For `end` mode in Claude Code, prefer a session-history-based review instead of reconstructing the session from memory.
`cc2md` is an optional prerequisite for this workflow; do not install or require it through hooks. If it is missing, tell the user and either continue with a normal agent-authored review or ask whether to install it.

This is a lightweight single-main-session aid, not a complete agent observability or multi-agent transcript graph. Do not try to automatically stitch unrelated sessions, subagent transcripts, Codex transcripts, or agent-team runs into one canonical history.

Use this flow:

1. Confirm `cc2md` exists.
2. Prefer one explicit Claude Code JSONL session for the current main agent. Do not rely on `latest` blindly.
3. If there is clear-context or plan/execution split risk, list the recent same-project sessions and recent plan files, then use the most relevant explicit session or mention that planning evidence was not included.
4. Export the selected session Markdown to `/tmp`.
5. Read the artifact and write a concise execution timeline review from it. For very long artifacts, summarize in chunks and then synthesize the final review.
6. Include lightweight source trace in the review body: exporter, session basename, artifact basename, and generated time. Do not include the full local path unless the user asks.
7. Dry-run the Linear comment, inspect the rendered body, then post for real only after the preview is acceptable.

Session selection should stay simple. If the correct session is ambiguous, show a short candidate list and ask for confirmation instead of building an interactive picker or guessing a multi-session graph.

```nushell
if ((which cc2md | length) == 0) {
    error make {msg: 'cc2md is required for session-history review. Install it or use a normal end review.'}
}

let issue = 'LUC-48'
cc2md list --json | from json | first 5 | select modified_at name project path size_bytes

let session = '<selected ~/.claude/projects/.../*.jsonl>'
let artifact = $"/tmp/linear-note-($issue)-(date now | format date "%Y%m%d-%H%M%S").md"
cc2md $session --output $artifact --markdown gfm --max-lines 0
$artifact
```

If clear-context likely split planning and execution, inspect nearby plan files as supporting context, but do not treat them as a transcript chain:

```nushell
ls ~/.claude/plans | sort-by modified --reverse | first 5
```

If the relevant planning session is not exported, say so in the review body instead of implying full coverage.

After writing the final review body from the exported artifact:

```nushell
'<execution timeline review>' | nu --stdin ~/.claude/skills/linear-note/scripts/linear.nu end --issue LUC-48 --agent claude-code --dry-run
'<execution timeline review>' | nu --stdin ~/.claude/skills/linear-note/scripts/linear.nu end --issue LUC-48 --agent claude-code
```

## Review Shape

For session-history-based `end` reviews, use this structure:

- `Session Source`: exporter, session basename, artifact basename, generated time, and whether planning evidence is included.
- `Execution Timeline`: chronological steps, including important pivots and why they happened.
- `Key Decisions`: decisions that changed scope, architecture, implementation, or verification.
- `Implementation`: concrete changes made.
- `Verification`: commands, checks, previews, or failures.
- `Risks / Follow-ups`: remaining uncertainty, skipped validation, or future work.

Do not paste the full session transcript into Linear by default. The transcript is the evidence source for the review, not the final comment body.

## Rules

- Do not use lifecycle hooks or wait for session end.
- Do not build or invoke an interactive session picker from this skill.
- Do not write note/checkpoint files. A `/tmp` session export is allowed only as source material for `end` review.
- Do not duplicate metadata headers; the script adds them.
- Do not post private chain-of-thought. Post conclusions, decisions, facts, and user-approved summaries only.
- Do not include `cc2md --thinking` unless the user explicitly asks and understands the privacy risk.
- Use `--dry-run` when previewing or validating formatting before posting.
- v1 session-history review covers the Claude Code main session only. Codex, subagents, and agent-team transcript graphs need a separate tool decision.
