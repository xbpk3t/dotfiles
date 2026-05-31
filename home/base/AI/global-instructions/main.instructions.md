---
description: Global Main Rules
applyTo: "**"
---

# Worktree 隔离规则

- Agent 不得隐式使用 `isolation: "worktree"` 创建 git worktree
- 需要 worktree 隔离的任务，须先询问用户确认，再通过 `EnterWorktree` 工具显式进入
- 只读/探索类任务无需 worktree，直接在主工作区进行
- 任务完成后调用 `ExitWorktree` 清理，不残留
