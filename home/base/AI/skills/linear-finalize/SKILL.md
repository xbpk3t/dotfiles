---
name: linear-finalize
description: Generate and post a final Linear issue retrospective for the current branch/session. Use when the user asks to finalize, close out, recap, summarize, or write a final review for a Linear issue.
trigger_keywords:
  - linear finalize
  - finalize issue
  - final review
  - session review
  - issue retrospective
  - 收口
  - 复盘
allowed-tools:
  - Bash
  - Read
---

# Linear Finalize

Generate a concise final retrospective for the current Linear issue, then post it with `linear-finalize`.

## Workflow

1. Gather local facts before writing the review:
   - `git branch --show-current`
   - `git status --short`
   - `git log origin/main..HEAD --oneline`
   - `git diff HEAD --stat`
   - any relevant verification commands already run in the session
2. Write the review body yourself. Do not ask the user to write it.
3. Pipe the review body into `linear-finalize`:

```bash
cat <<'EOF' | linear-finalize --agent codex --model "$MODEL"
## Plan

...

## Key Decisions

...

## Insights

...

## Implementation

...

## Verification

...

## Open Risks / Follow-ups

...
EOF
```

Use `--agent claude-code` when running from Claude Code. Use `--dry-run` first if the user asks to preview before posting.

## Rules

- Keep the retrospective factual and useful for future issue review.
- Include decisions and tradeoffs, not just changed files.
- Include verification status and any commands that were not run.
- Do not duplicate the metadata header; `linear-finalize` adds it.
- Do not use Codex `Stop` or Claude `SessionEnd` as the final review trigger.
