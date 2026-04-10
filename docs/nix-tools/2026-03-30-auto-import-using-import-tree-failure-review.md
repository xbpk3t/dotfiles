---
title: Auto Import Using import-tree Failure Review
type: review
status: done
date: 2026-03-30
updated: 2026-03-30
isOriginal: false
tags: [nix, import-tree, auto-import, flake-parts]
summary: 记录一次把现有 scanPaths 迁移到 import-tree 的失败尝试，说明为什么中途回滚，以及下次再做前需要先确认什么。
---

## TLDR

:::tip[TLDR]


这次尝试的目标，是把仓库里现有的 `scanPaths` 迁移到 [`vic/import-tree`](https://github.com/vic/import-tree)，并进一步减少中间层 `default.nix`。

最后选择回滚，不是因为 `import-tree` 不兼容 `flake-parts`，而是因为这次尝试在“想要的目标”和“实际采用的迁移方式”之间发生了偏差：

- 目标是：让 `import-tree` 直接接管 module discovery，并减少手写维护。
- 实际上中途走成了：先把 `scanPaths` 改写成一层新的 helper，再进一步把不少目录改成显式 `imports = [ ... ]`。

这两步都偏离了初衷，所以最终直接回滚。

:::



## 结论

- `import-tree` 与 `flake-parts` 本身兼容，这不是问题。
- 当前仓库不是不能做 auto import，而是不能在没有先约束“哪些 `.nix` 是 module、哪些不是”的情况下，直接全量递归接管。
- 这次失败的核心，不是工具能力不够，而是迁移策略不对。
- 如果以后再做，优先级应该是：
  1. 先界定 module / helper / data `.nix` 的边界
  2. 再决定哪些目录适合直接交给 `import-tree`
  3. 最后才开始删 `default.nix`

## 为什么失败

### 1. 目标是 auto import，实施却退化成了显式 imports

这次中途最明显的问题，是实现逐渐退化成了：

- 去掉 `scanPaths`
- 再去掉中间 helper
- 最后很多目录变成手写 `imports = [ ... ]`

这实际上等于把“自动导入”改成了“显式列举”，和最初目标相反。

如果最后需要大量手写模块列表，那这次迁移就没有真正带来结构收益。

### 2. 仓库里存在不少不是 module 的 `.nix`

当前仓库里，有一些 `.nix` 文件本质上是配置片段、数据文件、或仅供上层显式 `import` 的 helper，而不是标准 module。

典型例子：

- `home/base/desktop/IDE/zed/settings.nix`
- `home/base/desktop/IDE/zed/keymaps.nix`
- `home/base/desktop/IDE/zed/tasks.nix`
- `home/base/desktop/IDE/zed/themes.nix`

如果直接让 `import-tree` 递归吃完整棵树，而不过滤这些文件，就很容易误导入。

### 3. 当前很多 `default.nix` 不是纯聚合器

有些 `default.nix` 的确只是聚合目录，但也有不少 `default.nix` 自身承载了边界逻辑，例如：

- 附加 `home.packages`
- 前置导入某个共享模块
- Darwin / NixOS 平台配置
- 特定 option 的统一收口

这类文件不一定该删，至少不能在第一步直接删。

### 4. 迁移顺序错了

这次正确的迁移顺序，本来应该是：

1. 先画清楚哪些目录是“纯 module 树”
2. 哪些目录里混有 helper/data `.nix`
3. 再让 `import-tree` 只接管适合的目录
4. 最后再删纯聚合 `default.nix`

但实际尝试里，过早进入了“先删 / 先替换”的动作，结果就是路径越走越偏。

## 这次学到的东西

- `import-tree` 适合接“目录语义足够稳定”的模块树，不适合直接拿来粗暴替掉所有现有聚合层。
- `flake-parts` 兼容性不是主要阻碍，真正的难点是模块边界和过滤规则。
- 对当前仓库来说，`default.nix` 不能简单按“要不要保留”二分，更应该区分：
  - 纯聚合器
  - 真实边界模块
  - 同时带聚合与配置逻辑的混合模块

## 下次再做前，先检查什么

下次如果还想继续实现这个需求，先不要直接改代码，先做下面这几步：

- 列出所有“不是 module 的 `.nix` 文件”，尤其是只作为配置片段存在的文件。
- 列出所有“纯聚合 `default.nix`”。
- 列出所有“带额外逻辑的 `default.nix`”。
- 确认哪些目录可以安全交给 `import-tree` 递归。
- 确认过滤规则需要排除哪些 helper/data 文件。

只有这一步完成，后续迁移才可能真正减少维护，而不是从 `scanPaths` 退化成手写 imports。

## 备注

- 这次已经验证：直接上手改，不先做目录语义梳理，成本很高。
- 当前最稳妥的状态还是保留现有可工作的结构，等以后真要继续推进时，再先做“目录与模块边界清单”。
