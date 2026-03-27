---
title: Nix Tools
type: guide
status: active
date: 2026-03-25
updated: 2026-03-25
tags: [nix, tools]
summary: 当前仓库中与 Nix 本身强相关的 CLI 工具汇总，按职责分组。
---

# Nix Tools

本文只做汇总，不展开成教程。

## 1. 日常管理主入口

- `nh`: 高频 Nix/flake 管理入口，负责 `switch`、`clean` 等。
- `nixos-cli`: NixOS 主机上的系统管理 CLI，补充 build/apply/generation/option/manual 工作流。
- `nix-output-monitor`: 优化构建输出显示。
- `nvd`: 对比 generation / derivation 差异。

## 2. 索引 / 搜索 / 一次性执行

- `nix-index`: 查询“哪个包提供某个文件/命令”。
- `nix-index-database`: 预生成索引数据库，避免每台机器本地构建。
- `comma`: 用 `,rg`、`,jq` 这类形式临时运行 nixpkgs 工具。
- `noogle`: 搜索 Nix API / `lib` / `builtins` / 函数签名。

## 3. 开发环境与编辑器配套

- `direnv`: 进入目录时自动加载环境。
- `nix-direnv`: 给 `direnv` 提供更适合 Nix 的缓存与加载体验。
- `nixd`: Nix LSP。
- `nil`: 另一套 Nix LSP / 语言工具。

## 4. 开发 / 调试 / 格式化工具

- `deadnix`: 检查未使用变量/绑定。
- `statix`: 检查 Nix 风格与常见陷阱。
- `alejandra`: Nix 代码格式化。
- `nixfmt`: 仓库 `formatter` / `devShell` 使用的格式化器。
- `nixtract`: 从 derivation 提取源码/补丁等信息。
- `hydra-check`: 检查 Hydra 评估/依赖情况。
- `nix-melt`: 分析 store path 依赖树。
- `nix-tree`: 树状查看依赖。

## 配置落点

- `home/base/core/nh.nix`: `nh`、`nix-index`、`nix-index-database`、`comma`、`nix-output-monitor`、`nvd`
- `modules/nixos/base/nix-tools.nix`: `nixos-cli`
- `home/base/tui/langs/nix.nix`: `noogle`
- `home/base/tui/langs/direnv.nix`: `direnv`、`nix-direnv`
- `lib/langs.nix`: `nixd`、`nil`
- `home/base/tui/mac/devtools-nix.nix`: `deadnix`、`statix`、`alejandra`、`nixtract`、`hydra-check`、`nix-melt`、`nix-tree`
- `outputs/default.nix`: `nixfmt`、`deadnix`、`statix` 的 `devShell` / `formatter` 配置
