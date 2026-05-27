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
- `end`: post the final issue review/retrospective with git facts.

## Workflow

1. Decide the mode from the user's wording:
   - Use `latest` for `/linear-note`, “刷到 Linear”, “发到 Linear”, “post latest”, or an explicit note.
   - Use `end` for “finalize”, “final review”, “收口”, “复盘”, or issue retrospective.
2. Prepare the body yourself before calling the script:
   - For `latest`, keep it short and factual. If the target body is ambiguous, ask what to post.
   - For `end`, include plan, decisions, implementation, verification, and open risks/follow-ups.
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

## Rules

- Do not use lifecycle hooks or wait for session end.
- Do not write temporary note/checkpoint files.
- Do not duplicate metadata headers; the script adds them.
- Do not post private chain-of-thought. Post conclusions, decisions, facts, and user-approved summaries only.
- Use `--dry-run` when previewing or validating formatting before posting.
