---
title: 声明式管理skills
type: review
status: active
date: 2026-03-10
updated: 2026-03-10
slug: /2026/declarative-skills-management
unlisted: false
tags:
  - nix
  - LLM
---

这几天把 skills 的声明式管理跑通了，目标始终没变：希望能用 declarative 方式稳定管理常用 skills，同时保留临时技能的低成本使用体验。

一开始尝试过直接用 Taskfile 手搓流程，核心机制是对比本地 `.skill-lock.json` 和 YAML 清单，算出待安装列表再执行安装。这个方案能跑，但有两个明显问题：

- 本地自维护 skills 的 workflow 太重（`改 skills -> push -> skills update`），日常迭代成本高。
- skills-cli 的一些限制会放大维护成本，例如
  - `.skill-lock.json` key顺序不稳定导致乱序 diff
  - `mkOutOfStoreSymlink` 相关问题
  - 目前不支持基于 lock/json 的 global install（仅项目级）

后面切到 `agent-skills-nix`（ASN）后，主体问题基本解决，但也有代价：不支持类似 skills-cli 的 autoscan subdir，需要手动配置（并且需要在flake里配置相应repo，简单来说就是配置成本很高）。

---

之后发现codex本身就支持把skills放在多个folder下，那么决定把两套 skills 分开到两个目录（`.agents` 和 `.codex`）

最终落地的最佳实践是分层管理、双轨并行：

- 本地skills：由 `agent-skills-nix` 管理

<Github url="https://github.com/xbpk3t/dotfiles/blob/main/home/base/tui/AI/skills.nix" line={10} />

---

- 第三方skills(临时试用)：由 taskfile + skills-cli 管理

<Github url="https://github.com/xbpk3t/dotfiles/blob/main/.taskfile/works/AI/Taskfile.skills.yml" line={10} />

实际验证可以共存且不冲突
