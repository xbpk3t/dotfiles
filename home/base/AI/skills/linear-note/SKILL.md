---
name: linear-note
description: Deprecated alias for linear-latest-post. Use when the user types /linear-note, but immediately post via linear-latest-post instead of saving temp notes.
trigger_keywords:
  - /linear-note
  - linear-note
allowed-tools:
  - Bash
  - Read
---

# Linear Note

`linear-note` is kept only as a compatibility alias. Do not write temporary note files.

When the user asks for `/linear-note <content>`, treat it as `linear-latest-post <content>` and post immediately to the current Linear issue.

```bash
cat <<'EOF' | linear-latest-post --agent codex
<content>
EOF
```

Use `--agent claude-code` when running from Claude Code. If no content is provided, ask what should be posted instead of guessing.
