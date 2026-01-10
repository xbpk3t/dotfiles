---
description: Generate a Conventional Commit message from staged diff
argument-hint: [TYPE=<feat|fix|docs|refactor|test|chore>] [SCOPE=<scope>] [TICKET=<id>] [LANG=<en|zh>] [BODY=<0|1>]
---
You are generating a git commit message.

1) Run: git diff --staged
   - If there are no staged changes, reply exactly:
     No staged changes. Please run git add first.

2) Defaults:
   - TYPE=feat
   - SCOPE=api
   - TICKET="" (empty string)
   - LANG=zh
   - BODY=1

3) Produce a Conventional Commit subject line:
   - If TYPE is provided, use it; otherwise use the default.
   - If SCOPE is provided, format as: TYPE(SCOPE): <summary>
     If SCOPE is missing, format as: TYPE: <summary>
   - Keep subject <= 72 characters when possible.

4) If TICKET is provided (non-empty), include it at the start of the summary like:
   TYPE(SCOPE): [TICKET] <summary>

5) If BODY=1, add a blank line and up to 4 bullet points summarizing key changes.

6) Output ONLY the final commit message. No code fences, no extra commentary.
   - If LANG=zh, write the summary/body in Chinese (keep TYPE/SCOPE/TICKET as-is).
