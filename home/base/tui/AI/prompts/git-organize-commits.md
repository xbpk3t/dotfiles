---
name: git-organize-commits
description: Analyzes all working directory changes and organizes them into logical commit groups. Presents groupings for user approval before executing commits.
disable-model-invocation: true
allowed-tools: Bash(git *)
---

# Git Organize Commits

Analyze all changes in the working directory and organize them into logical, well-structured commits.

## Current state

- Status: !`git status --short`
- Staged changes: !`git diff --staged --stat`
- Unstaged changes: !`git diff --stat`
- Untracked files: !`git ls-files --others --exclude-standard`
- Recent commits: !`git log -10 --oneline`

## Steps

1. Analyze the current state shown above
2. If there are no changes (no staged, unstaged, or untracked files), inform the user and stop
3. If there are already staged changes, ask the user whether to respect the existing staging or reorganize everything
4. Gather detailed diffs for analysis:
    - Run `git diff` for unstaged changes (full diff, not just stat)
    - Run `git diff --staged` for staged changes (full diff)
    - For untracked files, run `git diff --no-index /dev/null <file>` to see contents
5. Group changes into logical commit units based on:
    - **Feature**: New functionality additions
    - **Fix**: Bug fixes
    - **Refactor**: Code restructuring without behavior change
    - **Docs**: Documentation changes
    - **Test**: Test additions or modifications
    - **Chore**: Build, config, dependency changes
    - **Style**: Formatting, whitespace changes
    - Files that are closely related (same module, same feature area) should be grouped together
    - Each group should represent ONE logical change
6. Present the proposed plan to the user:
   ```
   ## Proposed commit plan (N commits)

   ### Commit 1: <proposed commit message>
   Files:
   - path/to/file1
   - path/to/file2
   Summary: <brief description>

   ### Commit 2: <proposed commit message>
   Files:
   - path/to/file3
   Summary: <brief description>

   ---
   Proceed with this plan?
   ```
7. Wait for user approval. If the user requests changes, adjust and present again
8. Once approved, execute commits in order. For each group:
   a. Unstage everything if needed: `git reset HEAD`
   b. Stage files for the current group: `git add <file1> <file2> ...`
   c. Commit: `git commit -m "<message>"`
   d. Verify: `git status --short`
9. After all commits, show final state:
    - `git log --oneline -N` (N = number of commits created)
    - `git status --short`

## Rules

- NEVER amend existing commits unless explicitly asked
- NEVER use `--no-verify` flag
- NEVER run `git push` - only commit locally
- NEVER use `git add -A` or `git add .` - always stage specific files by name
- NEVER proceed without user approval of the commit plan
- If pre-commit hook fails, fix the issue and create a NEW commit
- Use conventional commit format: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `style:`, etc.
- Commit messages must be a single line, no line breaks
- Match language (English/Japanese) from recent commit history
- Keep commit messages short and concise, focus on "why" rather than "what"
- If a single file contains changes for different groups, keep it in ONE group (the most relevant one) and note this to the user
- Order commits logically: infrastructure/config first, then core logic, then tests, then docs
