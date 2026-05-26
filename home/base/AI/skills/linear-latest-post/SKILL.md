---
name: linear-latest-post
description: Immediately post the latest important agent response or explicit note to the current Linear issue. Use when the user asks to send, post, sync, or刷入 the latest/above response to Linear during a session.
trigger_keywords:
  - linear-latest-post
  - /linear-latest-post
  - 刷到 Linear
  - 发到 Linear
  - 写入 Linear
  - post latest to Linear
allowed-tools:
  - Bash
  - Read
---

# Linear Latest Post

Post the latest selected agent response or an explicit note to the Linear issue linked by the current branch.

## Workflow

1. Identify the body to post:
   - If the user provides content after `linear-latest-post`, use that content.
   - If the user says “把上面这段刷到 Linear” or similar, summarize the immediately preceding assistant response without adding new claims.
   - If the body is ambiguous, ask for clarification instead of posting the wrong content.
2. Keep the body concise and factual. This is an immediate session note, not the final issue retrospective.
3. Pipe the body into `linear-latest-post`:

```bash
cat <<'EOF' | linear-latest-post --agent codex
<body to post>
EOF
```

Use `--agent claude-code` when running from Claude Code. Add `--issue LUC-XXX` only when the branch cannot identify the issue.

## Rules

- Do not wait for `SessionEnd`; this command posts immediately.
- Do not duplicate the metadata header; `linear-latest-post` adds it.
- Do not use this for final review; use `linear-finalize` for full issue retrospectives.
- Do not post private chain-of-thought. Post conclusions, decisions, insights, or user-approved summaries only.
