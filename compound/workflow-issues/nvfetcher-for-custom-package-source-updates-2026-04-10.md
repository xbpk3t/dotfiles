---
title: Use nvfetcher to manage custom package source updates
date: 2026-04-10
category: workflow-issues
module: pkgs
problem_type: workflow_issue
component: tooling
severity: medium
applies_when:
  - repo 内存在自维护 package，且 upstream version / hash 更新频繁
  - package 的 builder 已经明确，不希望把 source 更新和打包逻辑混在一起
  - 需要统一管理 release artifact 或 GitHub source 的升级流程
tags:
  - nvfetcher
  - nixpkgs-packaging
  - source-updates
  - zashboard
  - fetchurl
  - fetchzip
---

# Use nvfetcher to manage custom package source updates

## Context

这个仓库已经有自维护 package，例如 `pkgs/zashboard/default.nix` 和 `pkgs/apple-pingfang/default.nix`。此前 source 信息主要靠手工维护，或者在注释里记录 `nurl` 的一次性生成结果。

这在单包阶段问题不大，但一旦想持续维护多个 package，就会出现两个摩擦点：

1. upstream version / hash 的更新是机械劳动，适合统一自动化；
2. builder 选型仍然需要按 package 类型分别处理，不能为了“统一升级”反过来把 package 结构搞复杂。

这次的目标不是引入新的 builder 体系，而是把 `nvfetcher` 放在 source update 层，专门负责生成 `version` 和 `src` 元数据。

## Guidance

把 `nvfetcher` 当作 source metadata generator，而不是 builder。

推荐结构：

1. 在主机工具集中引入 `nvfetcher` CLI，直接在仓库根目录运行：

```bash
nvfetcher -c nvfetcher.toml -o pkgs/_sources
```

2. 用 `nvfetcher.toml` 维护 upstream source 规则：

```toml
[zashboard]
src.github = "Zephyruso/zashboard"
fetch.url = "https://github.com/Zephyruso/zashboard/releases/download/$ver/dist.zip"
```

3. 用一个很薄的包装文件统一导入生成产物：

```nix
{
  fetchgit,
  fetchurl,
  fetchFromGitHub,
  dockerTools,
}:
import ./_sources/generated.nix {
  inherit
    fetchgit
    fetchurl
    fetchFromGitHub
    dockerTools
    ;
}
```

4. 在 `pkgs/default.nix` 把 source 集合显式传给需要它的包，而不是全局隐式读取：

```nix
pkgs:
let
  sources = pkgs.callPackage ./sources.nix { };
in
{
  zashboard = pkgs.callPackage ./zashboard {
    inherit sources;
  };
}
```

5. 在具体 package 里继续保留 builder 语义，只把 `version` / `src` 改为从 `sources.<name>` 获取。

`zashboard` 这次的关键点是：`nvfetcher` 对 URL source 默认生成的是 `fetchurl`，而不是原先手写的 `fetchzip`。这时不要回退到手工 hash，也不要为了省事重新引入 flake app 包装；正确做法是显式把解包语义写回 derivation：

```nix
stdenvNoCC.mkDerivation rec {
  pname = "zashboard";
  inherit (source) version src;
  nativeBuildInputs = [ unzip ];
  sourceRoot = "dist";
}
```

这样 source update 由 `nvfetcher` 统一生成，builder 仍然由 package 自己控制，边界清晰且易维护。

## Why This Matters

如果把 `nvfetcher` 误解成“统一打包工具”，很容易走向两个坏方向：

- 为了统一而强行改 builder，破坏原本已经很清晰的 package 结构；
- 把 flake app、额外 wrapper、repo-local shell 包装都堆进来，最后入口变多但收益很小。

这次的结论更稳妥：

- `nvfetcher` 处在 source update 层；
- `fetchurl` / `fetchzip` / `buildRustPackage` / `buildNpmPackage` / `crane` 这些仍然属于 builder 层；
- `nurl` 更偏一次性 prefetch，`nvfetcher` 更适合持续维护；
- `nix-init` 更偏起稿，`nvfetcher` 更偏后续升级维护。

这样做的收益是：

- source 升级流程统一；
- package 结构仍然保持按生态分别建模；
- 后续新增 package 时，可以渐进式接入，而不是一次性改造整个 `pkgs/`。

## When to Apply

- 仓库里已经有两个及以上需要长期维护的自定义 package
- package 的 builder 已经明确，只缺统一的 version / hash 维护入口
- upstream 提供 release artifact，或 source 规则足够稳定，适合交给 `nvfetcher.toml`
- 你希望 package 仍保持“一个包一个 derivation”的可读性，而不是上升到更重的统一打包框架

不适合直接照搬的情况：

- 只是一两个几乎不更新的 package，手工维护成本更低
- package 还在探索 builder 选型，此时应先解决 builder，再谈 `nvfetcher`
- source 类型需要很重的自定义抓取逻辑，`nvfetcher` 只能覆盖一部分机械更新

## Examples

### 例 1：推荐做法

`nvfetcher` 只负责生成：

```nix
zashboard = {
  version = "v3.3.0";
  src = fetchurl {
    url = "https://github.com/Zephyruso/zashboard/releases/download/v3.3.0/dist.zip";
    sha256 = "...";
  };
};
```

而 package 自己负责保留解包语义：

```nix
stdenvNoCC.mkDerivation rec {
  inherit (source) version src;
  nativeBuildInputs = [ unzip ];
  sourceRoot = "dist";
}
```

### 例 2：不推荐做法

把 `nvfetcher` 再包装成额外 flake app，再让包去依赖那层包装。这会增加入口数量，但不提升 source 管理能力。

### 例 3：和现有打包选型图的关系

对于 `docs/nix-tools/nixpkgs-pack.flowchart.puml` 里的工具，可以这样理解：

- `nvfetcher` 不替代这些 builder；
- 它是在这些 builder 之前，统一管理“从 upstream 拿什么版本、什么 source、什么 hash”；
- builder 的最终选型仍然要按 package 的生态和产物类型决定。

## Related

- `docs/nix-tools/nixpkgs-pack.flowchart.puml`
- `pkgs/zashboard/default.nix`
- `pkgs/sources.nix`
- `nvfetcher.toml`
