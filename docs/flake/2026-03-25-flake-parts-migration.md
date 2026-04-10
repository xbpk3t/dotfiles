---
title: flake-parts 迁移提纲
type: review
date: 2026-03-25
isOriginal: false
tags:
  - nix
  - flakes
  - flake-parts
summary: 记录将当前 flake 输出从 haumea 迁移到 flake-parts 时需要回答的问题和实现步骤。
---

## 为啥决定用 flake-parts 替代 haumea?

### 为什么决定迁移？

这部分要说明两个问题：

- 我原来为什么选 haumea
- 到了什么阶段发现它开始不合适

我一开始选 `haumea`，核心原因很简单：它的 `auto import` 很适合当时这套基于目录组织的输出结构。

当时我需要的是：

- 按目录聚合 `outputs/<system>/src/*.nix`
- 减少手写 import 列表
- 让 role 输出结构快速跑起来

在仓库规模还小时，这套方式是顺手的。

但随着仓库演进，问题开始出现：

- `auto import` 带来隐式行为，读代码时不够直接
- `outputs/*/default.nix` 这层逐渐变成纯 glue code
- `myvars` 开始承担过多职责，边界越来越模糊
- 测试链路一度和 `haumea` 绑定，迁移成本被放大

所以后期真正的问题，不是 `haumea` 不能用，而是它已经不再适合当前这套多平台、多 role、带 inventory 和 deploy 的仓库。

### 我做这个决策有哪些制约因素？

这次迁移不是从零重构，而是在现有仓库上做收敛，所以约束很多：

- 不能破坏当前 `role / host / inventory / deploy-rs` 的主结构
- 不能顺手引入一整套更重的新框架
- 不能把生产代码改成测试驱动的样子
- 必须同时兼顾 NixOS 和 nix-darwin 两条链路
- 迁移后要让代码更显式，而不是换一套新的隐式魔法

换句话说，这次迁移追求的是低阻力收敛，而不是“借迁移机会重做一遍架构”。

### 主流“Nix配置框架”横评


目前比较主流的“Nix配置框架”有：


```yaml

- haumea
- nixos-unified
- flake-parts

- snowfall-lib # 基于意见化文件结构的完整配置框架（以前基于 flake-utils-plus，现在 v2 独立）。
- blueprint # numtide/blueprint）：极简的「约定优于配置」文件夹映射框架。
- flakelight # 类似 flake-parts 但设计理念不同的模块化 flake 框架，强调自动加载和更少的 boilerplate。
# https://github.com/nix-community/flakelight

```



```csv

对比项,flake-parts,haumea,nixos-unified,snowfall-lib,blueprint,flakelight
基于 NixOS 模块系统,✅,❌,✅（基于 flake-parts）,❌（自有 mkFlake）,❌,✅
自动目录加载,❌,✅（核心功能）,❌（依赖 flake-parts）,✅,✅,✅
意见化文件结构,❌,❌,❌（提供模板但不强制）,✅,✅,❌
多平台统一支持,❌,❌,✅（专为 NixOS+Darwin+HM 设计）,✅,❌,❌
flake 输出自动化,✅,❌,✅（继承 flake-parts）,✅,✅,✅
boilerplate 减少程度,✅,✅（仅加载部分）,✅,✅（极致）,✅（最简）,✅
灵活性,✅（极高）,✅,✅（继承 flake-parts）,❌（意见化强）,❌（约定优先）,✅
社区流行度,✅（最流行）,✅（常用辅助库）,✅（个人配置常用）,✅（个人 NixOS 配置主流）,✅（新兴但增长快）,❌（较新/小众）

```


可以看到 nixos-unified 和 flakelight 都是基于 flake-parts 实现的

我们对这几个框架逐个判断：

- *nixos-unified, snowfall, blueprint 这三个框架，本身都钉死了文件结构，如果要迁移，要做完全的 refactor，但是收益却很有限，所以不做。*
- 那么剩下的就只有 flakelight 了，相较于 flake-parts 来说，其核心优势就在于支持 `Auto Import`，除此之外多了一些语法糖，可以把部分代码写的更简洁（比如说 1、更简单的 per-system 定义方式。2、overlays处理。3、flakelight 提供 src 参数给模块使用，方便自动设置 packages 等。）


但是综合来说还是最终选择了 flake-parts，原因有二：

- 1、实际上这个框架就是目前nix生态下的事实标准了，生态要好很多。
- 2、这个 `Auto Import`，之前用 `import-tree` 折腾过，发现迁移成本略高，收益很低（不如我现在 `scanPaths` 灵活易用）
- 3、查了一下发现上面的 table-vs 内容有问题。 flakelight 同样是“约定大于配置”的重框架（约定放到nix folder里，且有整套严格文件名称约定）。具体可以去看 [accelbread/config-flake](https://github.com/accelbread/config-flake) 参考。这个问题跟上面说 nixos-unified 的类似，同样迁移成本过高（而非略高了）。

所以最终选择了 flake-parts














### 【做出决策】这次迁移的目标，和明确不做的事情

目标：

- 去掉 haumea
- 收敛输出层
- 把 identity metadata 放回 inventory
- 清理 myvars
- 保留当前 role/host/inventory/deploy 的整体模型

非目标：

- 不切换到 nixos-unified
- 不引入 snowfall-lib
- 不顺手重写 deploy 体系
- 不为了测试引入新 DSL 到生产代码
- 不做一轮全面目录重构

这次最终选择 `flake-parts`，不是因为它“最强”，而是因为它最符合这次迁移的真实目标：在不推翻现有仓库模型的前提下，把输出层、元数据边界和框架耦合度收敛干净。

## 具体实现

### 几个关键问题

#### flake-parts不支持 auto import，怎么处理？

`flake-parts` 不负责替代 `haumea` 的 `auto import`。

所以这里的处理思路不是继续找一个同等魔法替代品，而是把这层行为显式化：

- 用 `flake-parts` 负责 flake 顶层组织
- 用 `outputs/default.nix` 自己做目录扫描和 merge
- 继续保留 `outputs/<system>/src/*.nix` 作为 role 输出单元

也就是说，这次迁移并没有放弃“目录驱动”，只是把“谁来聚合这些目录”从 `haumea` 改成了仓库自己显式控制。

#### 是否仍然需要保留 namaka?

最终判断是不需要。

原因不是 `namaka` 不好，而是它本身仍然依赖 `haumea`。既然这次迁移的目标之一就是彻底去掉 `haumea`，那继续保留 `namaka` 只会把旧依赖链重新带回来。

更重要的是，这次已经明确了一个边界：

- 测试代码应该放在 `tests/`
- 不应该继续侵入生产装配层
- 更不应该为了保留旧测试链路而反向保留旧框架

#### username 等var为什么必须从全局 myvars 拆回 host metadata？

因为这几个字段本质上不是“真正的全局变量”，而是主机身份的一部分。

`username / mail / timezone` 这类字段如果放在 `myvars` 里，短期看是省事，长期看会带来两个问题：

- 语义错误：它们其实属于 host/user identity，而不是全局常量
- 结构漂移：所有 host 都会被迫共享同一套身份假设

把它们放回 inventory 的好处是：

- 谁属于 host metadata，边界一眼就清楚
- 以后多用户、多主机、多时区时不会被全局变量结构拖死
- `specialArgs` 的注入语义也更自然

#### 为什么不接受 fallback 逻辑，而要强制从 meta 直接读取？

因为 fallback 会把“当前结构到底有没有收敛干净”这个问题掩盖掉。

像这种写法：

```nix
username = userMeta.username or myvars.username;
```

短期是兼容，长期是债务。

问题在于：

- 它会让旧结构继续存活
- 代码语义变模糊，不知道真实来源到底应该是谁
- 迁移看起来完成了，实际上只是加了一层兜底

所以原则很明确：

- 能从 `meta` 读，就只从 `meta` 读
- 不保留过渡性 fallback
- 让错误尽早暴露，而不是长期潜伏

### 【回归测试】先对原haumea的输出做固定，方便回归

从思路上看，这一步是对的：迁移框架时，最稳妥的方式就是先固定旧输出，再对照迁移后结果。

但这次实际落地时有个现实问题：

- 原来的 snapshot 测试链路依赖 `namaka`
- `namaka` 又依赖 `haumea`
- 而这次目标正是把这条依赖链彻底移掉

所以这一步最后没有保留为正式方案。

这次得到的结论是：

- 迁移时可以参考旧输出做人工或临时回归
- 但不应该为了保留旧 snapshot 体系而反向保留 `haumea`
- 后续测试应该单独放在 `tests/`，而不是侵入生产代码

### 具体修改（简述）

迁移分了哪几个阶段？

这个你们这次 chat history 里其实很清楚，建议明确按阶段写：

1. 先移除旧 outputs/\*/default.nix
2. 收敛 myvars 与重复 genSpecialArgs
3. 把 username/mail/timezone 拆回 host metadata
4. 清理 vars/default.nix / vars/networking.nix
5. 去掉 haumea
6. 再去掉 namaka
7. 最后补回非侵入式测试思路

这几步里，真正的主线其实只有两条：

- 收敛输出层
- 收敛元数据边界

其他清理工作，本质上都是围绕这两条主线做的。

### 补充 test case

这次迁移没有把新的测试体系一起定死。

原因很明确：

- 测试需要补
- 但不能以侵入生产代码为代价
- 更不能为了测试继续保留 `haumea/namaka`

因此后续测试策略应该遵守两个原则：

- 测试代码只放 `tests/`
- 生产路径不引入测试专用 glue code

### 最终效果

:::tip

删减了多少代码？提高了哪些可维护性？

:::

从当前实际状态看，这次迁移相关改动大致是：

- `113` 行新增
- `396` 行删除
- 净减少约 `283` 行

更重要的不是这个数字，而是删掉了哪些东西：

- 删除了 3 个旧的 `outputs/*/default.nix`
- 删除了旧 `vars` 层
- 删除了 `haumea`
- 删除了 `namaka`
- 删除了旧 snapshot 测试链路
- 删除了各种过渡性 fallback

可维护性的提升主要在这几条：

- flake 顶层组织更清晰，只剩 `flake.nix` + `outputs/default.nix`
- `globals` 和 host metadata 的边界更明确
- `specialArgs` 注入链路更显式
- role 文件职责更纯，不再夹杂过多框架 glue code
- 主代码路径不再依赖 `haumea/namaka`

除了这些，还获得了几个额外优势：

- 更接近社区主流，后续维护和协作成本更低
- 输出行为更可预测，不再依赖 `auto import` 魔法
- 以后继续扩 host / role / deploy 时，结构更稳
- 测试和生产代码的边界更容易划清

这次迁移最大的收益，不是“换成了 flake-parts”，而是把输出装配权和结构定义权重新收回到了仓库自己的显式代码里。

## 简要总结

这次迁移的核心不是“框架升级”，而是一次结构收敛。

`haumea` 在仓库早期是合适的，但随着仓库规模和复杂度上升，它开始把输出组织、元数据边界和测试链路都拖向更隐式的方向。`flake-parts` 的价值，不在于提供了更多功能，而在于它足够克制，允许我在不推翻现有仓库模型的前提下，把这些结构重新收敛干净。

最终结果是：

- 旧框架退出主路径
- 输出层被压平
- metadata 边界更清楚
- 代码整体更显式
- 后续继续演进的空间更大
