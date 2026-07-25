---
name: zzz
description: >
  Personal prompt router with dynamic subcommands.
  Routes /zzz <name> to references/**/<name>.md (name == filename stem).
  Composite prompts declare pipeline: [dep names] in frontmatter; atoms do not.
  Unknown subcommands print the available list and do nothing.
---

# /zzz — Personal Prompt Router

When the user invokes `/zzz <name>`, route to the corresponding prompt template:

1. Determine the skill directory path (same directory as this SKILL.md)
2. Run: `nu <skill_dir>/zzz.nu <skill_dir> <name>`
3. Read the file path returned by the script (relative to `<skill_dir>`)
4. Read that file’s frontmatter + body and execute as the current task:
   - **`role: atom`** — run the body only
   - **`role: composite`** — note `pipeline` (hard deps by name); when the body triggers a step, resolve that name via aliases and execute that file’s instructions, then continue the composite body

If the script returns "ERROR: unknown" or the name is unrecognizable, list available names and do nothing else.
