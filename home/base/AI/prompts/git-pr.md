---
name: git-pr
description: Used when creating pull requests. Generates PR title and description based on branch changes.
disable-model-invocation: true
argument-hint: [base-branch]
allowed-tools: Bash(git *), Bash(gh *), Read
---

# Git Pull Request

Create a pull request against base branch `$ARGUMENTS`.

## Current state

- Current branch: !`git branch --show-current`
- Status: !`git status --short`
- Remote tracking: !`git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "No upstream set"`

## Steps

1. Determine the base branch from `$ARGUMENTS` (default: `main`)
2. Gather context by running in parallel:
    - `git log <base-branch>...HEAD --oneline` to see all commits
    - `git diff <base-branch>...HEAD --stat` to see changed files
    - `git diff <base-branch>...HEAD` for full diff
3. Read the PR template:
    - Read `.github/PULL_REQUEST_TEMPLATE.md` or `.github/pull_request_template.md`
    - The PR body MUST follow the template structure exactly
4. Generate PR title and description:
    - Title: Short summary (under 70 chars), conventional commit format
    - Body: Fill in each section of the PR template based on the diff and commit history. Remove HTML comments from the template and replace them with actual content.
    - Match language (English/Japanese) from commit history
5. Push branch if needed:
   ```
   git push -u origin $(git branch --show-current)
   ```
6. Create PR using HEREDOC:
   ```
   gh pr create --draft --base <base-branch> --assignee mikinovation --title "title" --body "$(cat <<'EOF'
   <PR body here>
   EOF
   )"
   ```
7. Return the PR URL

## Rules

- Analyze ALL commits in the branch, not just the latest
- NEVER mention Claude Code or AI in PR content
- NEVER force push
- Always create as draft (`--draft`)
- PR body MUST follow the PR template structure. Fill in all sections with meaningful content based on the actual changes. Remove HTML comments and replace with real content.
- Always assign `mikinovation` as the PR assignee (`--assignee mikinovation`)
