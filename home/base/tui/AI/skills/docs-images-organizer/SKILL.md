---
name: docs-images-organizer
description: Organize docs-images folders by moving stray files into existing leaf folders or hidden .temp, with strict no-delete and minimal-structure-change rules.
---

# docs-images organizer

Use this skill when cleaning or organizing `docs-images` with strict non-destructive rules.

## Core rules (MUST)

- **Never delete files**. Only move.
- **Do not change overall structure**. Prefer existing leaf folders.
- **Hidden folders are allowed**. New folders must be hidden (`.temp` only) unless explicitly approved.
- **Random-name files** (e.g., timestamps or hash-like names) go to `.temp` in the current directory.
- **If no suitable leaf folder exists**, move to `.temp` in the current directory.

## Optional rules (ONLY if explicitly requested by user)

- **Delete empty files** when the user explicitly asks to remove empty artifacts.
- **Rename `未命名.*` files** based on content meaning; name format: max 2 words, joined by `-` (keep acronyms uppercase).
- **Match source files to same-stem SVG**: if a `.mmd`/`.puml` filename stem matches an existing `.svg` stem, move it into that SVG's directory.

## Workflow

1) **Scan target directory** (often `docs-images` or a subfolder) and list:
   - Files in the directory.
   - Leaf folders (directories with no children), including hidden ones.
2) **Classify filenames**:
   - Random-ish names (timestamps, long hex/uuid-like) → `.temp`.
   - Otherwise try matching existing leaf folder by filename stem (case-sensitive first, then case-insensitive) or by user-provided rules.
3) **Move files**:
   - Prefer matching leaf folder.
   - If no match, move to `.temp`.
   - Avoid overwrite by suffixing `.<n>`.
4) **Report**:
   - Print a move list (src → dst).

## Level-2 `.temp` consolidation (use only when user asks)

Target: `.temp` folders that are direct children of top-level categories (e.g., `algo/.temp`, `db/.temp`, `zzz/.temp`).

**Conservative mode (default):**
- Move only when there is a clear single destination:
  - Exact/CI match between file stem and leaf folder name
  - Or a unique, obvious substring match
- Otherwise leave in place.

**Aggressive mode (only if user explicitly wants it):**
- Select the best leaf folder by filename/leaf-name similarity (containment > fuzzy).
- Skip low-confidence matches and `.DS_Store`.
- If still unsure, keep in `.temp` rather than inventing folders.

## Random-name detection (guideline)

Treat as random if filename stem matches one of:
- `^\d{10,}$`
- `^[0-9a-f]{8,}(-[0-9a-f]{4,}){2,}`
- `^[0-9a-f]{16,}$`
- `^\d{10,}[A-Za-z0-9]+$`

## Safety notes

- Never remove or rename directories unless explicitly asked.
- If a move would overwrite an existing file, append `.<n>`.
- If you are unsure about a match, default to `.temp` rather than creating new folders.
