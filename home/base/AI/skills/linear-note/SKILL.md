---
name: linear-note
description: Save a note during an agent session. Use /linear-note <content> to record a timestamped note that will be included by linear-finalize.
trigger_keywords:
  - /linear-note
allowed-tools:
  - Bash
  - Read
  - Write
---

# /linear-note -- Save a note for the Linear issue review

Records a timestamped note in an issue-scoped temp file. `linear-finalize`
includes these notes in the final Linear issue retrospective.

## Usage

When the user types /linear-note <content>, save their note:

1. Detect the issue key from the current branch:

   ```bash
   ISSUE_KEY=$(git branch --show-current | grep -Eio 'LUC-[0-9]+' | head -1 | tr '[:lower:]' '[:upper:]')
   ```

2. If `ISSUE_KEY` is empty, fall back to `/tmp/linear-session-notes.md`; otherwise use `/tmp/linear-session-notes-$ISSUE_KEY.md`.

3. Append the note in this format:

   ```markdown
   > **HH:MM** -- <content>
   ```

4. Confirm: "Note saved."

## Notes

- Multiple /linear-note calls accumulate in the same issue-scoped temp file.
- `linear-finalize` reads and clears the issue-scoped notes file after posting unless `--keep-checkpoints` is used.
- Claude Code `SessionEnd` may post a lightweight checkpoint, but it does not clear notes.
