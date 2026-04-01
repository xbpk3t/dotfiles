---
title: 声明式管理skills
type: guide
status: active
date: 2026-03-10
updated: 2026-03-10
slug: /2026/declarative-skills-management
unlisted: false
tags:
  - nix
  - LLM
  - skills
summary: 总结本仓库当前的 skills 分层管理方案，以及 agent-skills-nix 与 skills-cli 的职责边界。
---


## 对skills拆分管理 [2026-03-10]

这几天把 skills 的声明式管理跑通了，目标始终没变：希望能用 declarative 方式稳定管理常用 skills，同时保留临时技能的低成本使用体验。

一开始尝试过直接用 Taskfile 手搓流程，核心机制是对比本地 `.skill-lock.json` 和 YAML 清单，算出待安装列表再执行安装。这个方案能跑，但有两个明显问题：

- 本地自维护 skills 的 workflow 太重（`改 skills -> push -> skills update`），日常迭代成本高。
- skills-cli 的一些限制会放大维护成本，例如
  - `.skill-lock.json` key顺序不稳定导致乱序 diff
  - `mkOutOfStoreSymlink` 相关问题
  - 目前不支持基于 lock/json 的 global install（仅项目级）

后面切到 `agent-skills-nix`（ASN）后，主体问题基本解决，但也有代价：不支持类似 skills-cli 的 autoscan subdir，需要手动配置（并且需要在flake里配置相应repo，简单来说就是配置成本很高）。


```yaml

# [2026-03-08] 直接用taskfile管理第三方skills了，所以注释掉
#  home.file.".agents/.skill-lock.json" = {
#    source =
#      config.lib.file.mkOutOfStoreSymlink
#      "${config.home.homeDirectory}/Desktop/dotfiles/home/base/tui/AI/.skill-lock.json";
#
#    force = true;
#  };
```



---

之后发现codex本身就支持把skills放在多个folder下，那么决定把两套 skills 分开到两个目录（`.agents` 和 `.codex`）

最终落地的最佳实践是分层管理、双轨并行：

- 本地skills：由 `agent-skills-nix` 管理

https://github.com/xbpk3t/dotfiles/blob/main/home/base/tui/AI/skills.nix

---

- 第三方skills(临时试用)：由 taskfile + skills-cli 管理

https://github.com/xbpk3t/dotfiles/blob/main/.taskfile/works/AI/Taskfile.skills.yml

实际验证可以共存且不冲突



## zzz [2026-03-29]


今天看到的，所见略同。我对于 skills 直接根据是否自用，拆分到两个folder，是非常好的实践

[李继刚 on X: "把遇到的问题分为两类：通用类和私有类。 通用类需求，比如获取任意网页内容，一定有很专业的人在研究，没必要重新发明轮子，不论是开源的或是付费的，直接找到最好用的取用即可。 私有类需求，比如你读书时就喜欢使用某种自己沉淀下来分析框架，外面哪怕有再多相关" / X](https://x.com/lijigang/status/2038090572800606262)


## 把CORE skills也纳入声明式管理 [2026-03-31]

:::tip[TLDR]

绕了一大圈，走了很多弯路，最终还是走回原点，也算是目前最佳实践了

- 把 CORE skills 纳入 `agent-skills`的声明式管理
- 把分散、又不怎么更新的（仍然需要使用的）skills 直接拖到local，直接管理。比如说新增的 `duckdb`, `typst`, `nushell-best-practices` 这几个


:::



https://x.com/kasong2048/status/2038599301618889042

### 背景



手头的skills太乱了（尤其是第三方），所以下午又去尝试整理一下。

一开始想到的是分为 CORE, OPTIONAL, DEPRECATED 这么三组，分别是 必须、可选、待删。

所以一开始沿着这个思路打算修改一下taskfile

结果非常麻烦，代码可维护性很差，最后让codex帮我直接用 nushell 实现，才算是实现需求的同时，也保证了代码的简洁和可维护性。

但是具体用了一下workflow发现，仍然很变扭。

### 当时设想的交互式 workflow

具体来说当时的需求：

```markdown
- 交互式（易用性）有限。只需要一个（default task）作为入口。
- full/pick, install/remove 这些都用 gum confirm 处理，GROUP (CORE/OPTIONAL/DEPRECATED) 用 gum choose 处理。并且直接把这些做到 `vars.sh` 里，
- 为了保证可维护性，如果逻辑比较复杂，应该使用nushell
```






### 为什么这个 workflow 仍然很变扭

比如说 我现在的这个场景，我在把大量CORE的skill挪到其他var里，打算批量卸载掉，
按照我们之前的方案是，挪到 DEPRECATED 卸载后，再挪到其他var里


但是这个workflow就不合理，不是吗？更好的流程是，我直接按照理解，挪到 OPTIONAL

里面，然后执行时直接批量执行，进行卸载。这是更好的方案，你觉得呢？

但是如果都批量执行也会带来问题，也就我有时可能偶尔需要安装 OPTIONAL 里的某个
skill，所以需要我上面说的 gum choose (又或者说你觉得可能 gum filter 更好？这
点需要讨论)

具体代码没什么好说的，都是让codex直接实现的。只不过看到具体代码之后，我就知道“这个不是我要的东西”，所以全部rollback了。


> 绕了一大圈无非是再次证明了，***“归根到底问题还是在于 这种命令式的skill管理终究还是无法做到强一致性”***

### 最终决策

所以我转念一想，***我的理念是对的，要拆分、要分级（也就是打score）*** 那我为啥不把这些 `CORE` 都纳入到 `agent-skills` 管理呢？

思路理顺了，后面的具体实现就很顺了。

直接把所有 `score = 5` 的 repo（代表“确认会长期存在”的skills） 都直接迁移到 nix里了，但是迁移过来之后就想到了为啥之前没用nix管理这些第三方skills了，具体来说，以下三点：

- 1、`agent-skills`里 repo跟skills拆开到两块了，就导致可维护性也会变差。
- 2、需要在 `flake.nix` 里添加这些skills的repo
- 3、担心如果只用nix来管理skills的话，有时临时添加和删除skills还需要重新rebuild，非常麻烦。
- 4、`agent-skills` 需要手动配置 `subdir`，而非 skills cli这种会自动扫描 subdir，就会很麻烦，维护成本也更高。


以上三点里，第一点最核心，第二点解决不了（是nix/flake本身的限制），第三点则通过把这部分skills拆分到taskfile解决（也就是我上一轮所做的事情）

***所以做了一个关键决策：第三方 skills metadata 抽离到 `skills-catalog.nix`***

也就解决掉了上面所说的这个之前以来一直困扰我的问题。上点价值的话，其实还是一直以来的那个话，“遇到问题不要绕，认准了就去解决”，其实说来说去最核心的还是上面说的“`agent-skills`里 repo跟skills拆开到两块，很难维护”的问题，正确的思路应该是，***我终究是需要声明式管理skills的，所以这个问题是需要去解决的，而非像之前一样，直接把local和remote两种skills拆分。***





## 移除部分第三方skills [2026-04-01]



```yaml

# https://x.com/axiaisacat/status/2030297324962857044
# https://github.com/pbakaus/impeccable
# how to use: https://impeccable.style/cheatsheet
- repo: pbakaus/impeccable
  score: 4 # 建议归类(OPTIONAL)
  skills:
    - adapt
    - animate
    - audit
    - bolder
    - clarify
    - colorize
    - critique
    - delight
    - distill
    - extract
    - frontend-design
    - harden
    - normalize
    - onboard
    - optimize
    - polish
    - quieter
    - teach-impeccable


```


`pbakaus/impeccable` 本身不是“没用”，相反它是一整套很强的前端设计工具箱，覆盖 design critique、layout/typography/color 调整、polish、harden、optimize 等多个方向，并且明确反对 AI slop。问题在于它的使用前提比较重：很多子 skill 都要求先建立设计上下文，再按具体命令手动调用，所以它更像一套专项工作台，而不是适合长期留在第三方声明式清单里的通用 skills。

因此这里最终选择把它从第三方 skills 清单里移除，而不是继续放在 taskfile / skills-cli 管理。核心原因不是能力不足，而是它更适合按项目、本地直接管理和按需使用；放在 declarative 的第三方清单里，噪音会偏大，也不符合当前这套“CORE declarative + 专项 local”的分层思路。
