---
name: linear-flow
description: End-to-end Linear-driven development workflow. Use when implementing a Linear issue from start to PR — creates worktree, executes task, posts insights, opens PR. Triggers on "implement LUC-XX", "ship LUC-XX", "work on issue", "start LUC-XX".
trigger_keywords:
  - implement LUC
  - ship LUC
  - start LUC
  - work on issue
  - linear flow
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - mcp__plugin_claude-code-home-manager_linear__*
  - mcp__plugin_claude-code-home-manager_github__*
---

# Linear Flow — Issue-to-PR Orchestration

End-to-end workflow: Linear issue → worktree → implementation → insights → PR.

---

## Prerequisites

- `LINEAR_API_KEY` auto-injected by Nix (`home.sessionVariables` in `mcp.nix`)
- `gh` CLI authenticated (`gh auth status`)
- Git worktree support in the repo

---

## Workflow

### Step 1: Start the issue

```bash
linear issue start <ISSUE_KEY>
```

This creates a branch (e.g., `luc/LUC-16-slug`) and sets the issue to **In Progress**.

### Step 2: Create worktree (optional, for isolation)

```bash
BRANCH=$(linear issue view <ISSUE_KEY> --json | jq -r '.branchName')
git worktree add ../<ISSUE_KEY>-worktree "$BRANCH"
cd ../<ISSUE_KEY>-worktree
```

Skip if already on the correct branch.

### Step 3: Implement

Do the actual work. Follow the issue's acceptance criteria. Commit with the issue key in the message:

```bash
git commit -m "feat(scope): description (<ISSUE_KEY>)"
```

### Step 4: Verify

Run project-specific checks (e.g., `task y2m:check`, `nix flake check`, test suite).

### Step 5: Post insights to Linear

```bash
cat > /tmp/linear-insights.md <<'EOF'
## Changes
- file1 — what changed
- file2 — what changed

## Key decisions
- decision 1
- decision 2

## Verification
- check 1: pass
- check 2: pass
EOF

linear issue comment <ISSUE_KEY> --body-file /tmp/linear-insights.md
```

### Step 6: Push and create PR

```bash
git push -u origin HEAD
gh pr create --title "feat: <summary> (<ISSUE_KEY>)" --body "Closes <ISSUE_KEY>"
```

---

## Guardrails

- Never start implementation without `linear issue start` first — the branch name is the contract with Linear's GitHub integration.
- Always include the issue key in commit messages and PR body — this triggers automatic status transitions.
- If a worktree was created, clean it up after merge: `git worktree remove ../<ISSUE_KEY>-worktree`.
- Post insights BEFORE creating the PR so reviewers have context.

---

## Quick Reference

```bash
# One-shot: start, work, ship
linear issue start LUC-16                    # Step 1
git worktree add ../LUC-16-worktree luc/LUC-16-slug && cd ../LUC-16-worktree  # Step 2
# ... implement, commit, verify ...           # Steps 3-4
linear issue comment LUC-16 --body-file /tmp/insights.md  # Step 5
git push -u origin HEAD && gh pr create --body "Closes LUC-16"  # Step 6
```
