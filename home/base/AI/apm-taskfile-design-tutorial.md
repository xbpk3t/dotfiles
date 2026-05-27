# 用当前仓库讲明白 APM + Taskfile 设计判断

这篇文档不是操作手册，也不是直接改配置的方案说明。

它只做一件事：用当前仓库的真实案例，讲清楚为什么 `.taskfile/works/Taskfile.apm.yml` 现在的问题，不是“task 太多”或者“task 太少”，而是把多条不同语义的 APM 工作流混在了一个默认入口里。

如果你只想先记住一句话，那就是：

> 一个 task 可以很重，但不能很混。少 task 不是问题，少 task 却承载多条未对齐的语义线，才是设计问题。

## 1. 先把一个误区拿掉：不要用 task 数量判断设计好坏

很多人看到 Taskfile 的第一反应是：

- task 越少越好
- 能组合就不要拆
- 如果每个命令都暴露成 task，还不如直接敲 CLI

这个方向本身没有问题。

问题在于，`少 task` 只是接口偏好，不是架构原则。真正的架构原则是：

- 一个公开入口最好只服务一条主语义
- 默认工作流内部的每一步，最好都属于同一条语义线
- 这个入口对外讲的故事，要和 manifest、lockfile、dry-run、audit 的事实一致

所以，判断一个 APM Taskfile 是否设计良好，第一步不要问：

- “它拆得够不够细？”

而是先问：

- “它默认入口到底代表什么？”
- “默认入口里的步骤是不是同一类事情？”

只要这两个问题答不清，task 再少也会乱。

## 2. 先把 APM 看成几条不同的语义线

你当前这份 Taskfile 的症结，只有在先区分 APM 的几条 lane 之后才看得清。

### 2.1 `compile` lane

`compile` 关心的是 instruction 如何被聚合、继承、布局，最终编译成某类 prompt/context 文件。

它回答的问题是：

- 当前有哪些 instruction 会参与编译
- 它们会被放到哪里
- 编译产物长什么样

它不天然回答这些问题：

- 当前 runtime 是否已经被正确部署
- lockfile 是否和磁盘状态一致
- install 结果是否已同步

### 2.2 `install` lane

`install` 关心的是“把 APM 项目的部署结果同步到 runtime 目标位置”。

它回答的问题是：

- 目标 runtime 目录里应该有哪些部署文件
- lockfile 和 manifest 描述的部署状态是否落到了磁盘上
- 多余文件是否需要被清掉

它不天然等价于：

- compile 通过
- instruction 布局最优
- repo 内 AGENTS.md 编译策略合理

### 2.3 `update` lane

`update` 的语义是“推进状态”，不是“同步现状”。

它会刷新依赖和 lockfile，因此它和 `install` 关系紧密，但不是同义词。

如果一个默认入口包含 `update`，那它对外讲的故事就不再是“安装”或“部署”，而更接近“维护”或“升级同步”。

### 2.4 `audit` lane

`audit` 的语义是校验和诊断。

它关心的是：

- drift
- lockfile 完整性
- policy
- 内容完整性

它不负责生成产物，也不负责刷新依赖。

### 2.5 `targets` / `list` / `deps` 这类命令

这些更偏观察层。

它们回答：

- 当前项目是怎么被解析的
- 当前有哪些 targets / scripts / deps

它们可以服务于任何 lane，但它们本身不定义主线。

## 3. 回到你的 Taskfile：它表面上是一个 workflow，实际上混了多条 lane

先看当前 `.taskfile/works/Taskfile.apm.yml` 的公开叙事：

```yaml
# 日常 workflow:
#   task apm          → 全流程: info → compile → update → prune → install
```

对应定义是：

```yaml
default:
  desc: 默认任务，编译并安装所有 APM skills
  deps: [_check]
  cmds:
    - task: _info
    - task: _compile
    - task: _update
    - task: _prune
    - apm install
```

问题不在于“它组合了五步”。

问题在于这五步不属于同一条语义线：

- `_info` 是观察层
- `_compile` 是 compile lane
- `_update` 是 update lane
- `_prune` 和 `apm install` 更接近 deploy/install lane

这就是整个设计判断的起点：

> 你这里不是单纯做了一个重 workflow，而是把不同性质的 workflow 串成了一个默认入口。

如果这几步最后都指向同一套事实模型，那还可以接受。

但在当前仓库里，它们已经不再指向同一套事实模型了。

## 4. 用仓库里的真实证据看“哪里没对齐”

这一节只做一件事：把“感觉乱”变成“证据链清楚地说明为什么乱”。

### 4.1 证据一：Taskfile 对 compile 的叙事

当前 `_compile` 的注释和命令是这样的：

```yaml
_compile:
  desc: 编译 instructions → CLAUDE.md + AGENTS.md
  cmds:
    - apm compile --validate
    - apm compile --dry-run
    - apm compile --target claude,codex
```

这段叙事隐含了两个判断：

- compile 是这条默认 workflow 的自然组成部分
- compile 的产物语义是 `CLAUDE.md + AGENTS.md`

如果这两个判断都成立，那么后面的 manifest、lockfile、install 结果最好和它一致。

### 4.2 证据二：manifest 实际声明的 target

当前 `apm.yml` 很短：

```yaml
targets:
  - claude
includes: auto
```

这至少说明一件事：

- 项目 manifest 当前公开声明的目标只有 `claude`

但 `_compile` 里却直接写了 `--target claude,codex`。

这不一定是错，但它至少意味着：

- Taskfile 的默认工作流语义，已经开始偏离 manifest 的公开叙事

换句话说，Taskfile 在替 manifest 做额外决策。

### 4.3 证据三：lockfile 追踪的真实部署文件

当前 `apm.lock.yaml` 的关键内容是：

```yaml
dependencies: []
local_deployed_files:
  - .claude/rules/dotfiles.md
  - .github/instructions/dotfiles.instructions.md
```

这很关键，因为它说明当前 lockfile 追踪的“事实模型”是：

- 这是一个有本地部署文件的项目
- 它当前记录的是 runtime-native 部署结果
- 它记录的不是根目录 `AGENTS.md`
- 它也没有记录什么 codex 侧编译输出

到这里，第一层冲突已经出现了：

- Taskfile 的 compile 叙事说的是 `CLAUDE.md + AGENTS.md`
- lockfile 记录的事实却是 `.claude/rules/...` 和 `.github/instructions/...`

这两者不是同一套产物模型。

### 4.4 证据四：compile dry-run 的真实行为

我实际跑了：

```bash
apm compile --dry-run --target claude,codex -v
```

关键输出是：

```text
[i] Targets: claude, codex  (source: --target flag)
[i] Compiling for AGENTS.md + CLAUDE.md (--target claude,codex)

Pattern      Source                 Placement
**           dotfiles.instructions  ./AGENTS.md
**           codegraph.instructions ./AGENTS.md

[DRY RUN] Would generate 1 AGENTS.md file
```

这个输出证明了几件事：

- 当前 compile lane 确实在朝根目录 `AGENTS.md` 方向工作
- 它参与编译的不只有 `.apm/instructions/dotfiles.instructions.md`
- 还包括 `home/base/AI/global-instructions/codegraph.instructions.md`

这又说明一个很重要的事实：

> 你这里的 compile lane，不是“本地 `.apm/` 小闭环”，而是已经把 repo 里的其他 instruction 源一起拉进来了。

这会直接影响 Taskfile 设计判断，因为 compile 已经不是一个轻量附属动作，而是一条有自己输入边界的主线。

### 4.5 证据五：install dry-run 的真实行为

我实际跑了：

```bash
apm install --dry-run
```

关键输出是：

```text
[i] No dependencies found in apm.yml
[i] Files that would be removed (packages no longer in apm.yml): 2
[i]   - .claude/rules/dotfiles.md
[i]   - .github/instructions/dotfiles.instructions.md
```

这说明什么？

- install lane 当前依据 manifest/lock 的理解，认为这两个文件会被移除
- 也就是说，install lane 对“当前应该保留什么部署文件”的理解，和 repo 现状已经不一致

这不是抽象设计争论，而是实际状态已经出现冲突。

### 4.6 证据六：audit 已经看到了 drift

我实际跑了：

```bash
apm audit --ci
```

关键输出是：

```text
[!] Drift detected: 1 file(s)

drift details:
  - orphaned: .claude/rules/dotfiles.md
```

这说明：

- 现在的问题不是“只是文案不准”
- APM 自己已经在说：当前部署事实和它理解的状态不一致

也就是说，这个 Taskfile 不是“设计上抽象不清但暂时还能跑”，而是已经踩到了真正的状态漂移。

## 5. 所以这里的问题到底是什么

到这里可以把问题说得很准确了。

当前设计的问题不是：

- workflow 太长
- 组合太多
- 默认 task 太重

当前设计真正的问题是：

- 默认入口把 `compile`、`update`、`install` 三条不同语义线放在一起
- 这些 lane 对“项目应该产出什么”并没有共享同一个事实模型
- Taskfile 注释、manifest、lockfile、dry-run、audit 已经开始互相打架

这就是我为什么说它是设计问题，而不是简单的写法问题。

因为当一个默认入口同时承担多条 lane 时，用户无法从名字判断：

- 这次跑 `task apm` 到底是在“编译 instruction”
- 还是在“推进 lockfile 状态”
- 还是在“同步 runtime 部署结果”

如果其中任何一步失败，你也很难立刻知道：

- 是 compile 模型错了
- 还是 install 模型错了
- 还是 lockfile 已经过时

这就是“一个 task 可以很重，但不能很混”的具体含义。

## 6. 正确的 APM 设计，不是“拆更多 task”，而是先选主线

这里最容易误解的一点是：

> 说当前设计有问题，不等于我认为必须把每个 CLI 都拆成一个 task。

不是这个意思。

正确的 APM 设计，先要做的不是拆，而是回答：

- 这个仓库的默认入口到底服务哪条主线

只要主线选清楚，task 可以仍然很少。

### 6.1 模式一：compile-first

如果一个仓库的核心目标是“编译 instruction 并产出 AGENTS/CLAUDE 之类的上下文文件”，那么默认入口可以围绕 compile lane 组织。

这种模式下：

- source of truth 是 instruction 集合和 compile 布局
- `compile --validate`、`compile --dry-run`、`compile` 本身是一条自然 workflow
- `install` 要么不存在，要么只是次级动作

这时把 compile 放进默认入口是合理的。

### 6.2 模式二：deploy-first

如果一个仓库的核心目标是“把 APM 管理的 runtime 文件同步到正确位置”，那么默认入口可以围绕 install/deploy lane 组织。

这种模式下：

- source of truth 是 manifest + lockfile + deployed files
- `prune`、`install`、必要时的 `update` 可以被组合成一个维护入口
- compile 不应默认混进来，除非它和部署产物模型完全同向

注意这里的重点不是“不能组合”，而是：

- 组合必须围绕 deploy 这条主语义

### 6.3 模式三：dual-lane，但必须显式承认

如果一个仓库确实同时需要：

- 一条 compile 主线
- 一条 deploy 主线

那也不是不能做。

但它必须显式承认自己有两条 lane，而不是把两条 lane 伪装成一条默认 workflow。

这时正确的设计重点不是“多 task”，而是：

- lane 要有清晰边界
- 用户要知道自己在跑哪条主线
- 默认入口和卫星入口的语义必须说得明白

## 7. 放回当前仓库：它今天更像哪种模式

根据当前证据，这个仓库今天更像一个 **deploy-first** 项目，而不是 compile-first 项目。

原因很简单：

- `apm.yml` 明确声明了 `claude` target
- `apm.lock.yaml` 明确记录了 deployed files
- `apm audit --ci` 也在围绕部署状态检查 drift

也就是说，APM 在这个仓库里最稳定的事实模型，目前仍然是：

- 它在管理 runtime-native 部署结果

而 compile lane 当然存在，但它现在：

- 参与的 instruction 源更多
- 产物模型不同
- 和 lockfile/deploy 事实模型没有完全对齐

这就是为什么我会说：

> 当前默认 `task apm` 把 compile 混进去，不是因为 compile 不重要，而是因为它已经足够独立，不能再被假装成 deploy workflow 的一部分。

## 8. 当前 Taskfile 还有哪些次级设计问题

这些不是主矛盾，但它们会放大混乱感。

### 8.1 头部文案宣传了不存在的公开接口

文件头写了：

- `task apm:info`
- `task apm:update`
- `task apm:prune`

但当前定义里这些都是 internal task，没有真正公开出来。

这意味着：

- 文档 surface 和真实 surface 不一致

这不是大架构问题，但会直接破坏可发现性。

### 8.2 `_check` 把多个失败原因糊成一条报错

当前 `_check` 的 precondition 是：

```yaml
command -v apm >/dev/null && test -f apm.yml
```

它的问题不是逻辑错误，而是诊断粒度太粗。

当它失败时，你不知道：

- 是 `apm` 没在 PATH
- 还是当前目录没 `apm.yml`
- 还是 task shell 环境和交互 shell 不一致

这类问题不决定主线，但会影响排障质量。

### 8.3 `_info` 现在更像“拼接输出”，不像明确的诊断入口

当前 `_info` 做的是：

- `apm targets`
- `apm outdated || true`
- `apm list || true`

它的问题不是命令不对，而是：

- 这些输出分别服务不同判断层
- 它们没有被组织成一个清晰的诊断叙事

所以 `_info` 看起来像“有信息”，但不一定能回答“当前主线是否健康”。

## 9. 以后你自己怎么判断一个 APM Taskfile 是否设计正确

以后你遇到类似配置，可以按这个顺序判断。

### 9.1 第一步：先写出默认入口的一句话语义

比如：

- “这是 compile 入口”
- “这是部署同步入口”
- “这是维护升级入口”

如果一句话说不清，那设计大概率已经开始混了。

### 9.2 第二步：给默认入口里的每一步标 lane

你只需要问：

- 这是 compile lane？
- install lane？
- update lane？
- audit lane？
- 还是观察层？

如果一个默认入口里出现了多条 lane，不代表一定错，但必须继续问第三步。

### 9.3 第三步：看这些 lane 是否共享同一套事实模型

这里最关键。

你要对照：

- Taskfile 注释
- manifest
- lockfile
- dry-run
- audit

只要其中两个以上已经开始描述不同的产物模型，这个入口就该被重新设计。

### 9.4 第四步：区分“推进状态”和“校验状态”

`update` 是推进状态。

`audit` / `validate` 更偏校验状态。

`install` 是同步状态。

这三类动作可以被组合，但组合前必须先知道你到底要向用户提供什么承诺。

### 9.5 第五步：最后才讨论 task 要不要拆

这是最后一步，不是第一步。

如果主线清晰，task 完全可以很少。

真正不好的情况不是“task 少”，而是：

- task 很少
- 但每个 task 都在同时承载多套不同的系统模型

## 10. 这篇教程真正想让你记住什么

如果把整篇文档再压缩一次，我希望最后留下的是下面四句话。

1. 不要用 task 数量判断设计优劣，先看默认入口代表哪条主线。
2. APM 至少要分清 compile、install、update、audit 这几条 lane。
3. 当前这份 Taskfile 的问题不是组合太多，而是 compile/deploy/update 的事实模型已经不一致。
4. 正确设计不是先拆 task，而是先决定仓库到底是 compile-first、deploy-first，还是 dual-lane。

当你把这四句话真正吃透之后，再回去看 `.taskfile/works/Taskfile.apm.yml`，你就不会再只盯着“命令有没有组合好”，而会开始问更本质的问题：

- 这个默认入口到底在代表谁
- 它和 APM 当前真正的 source of truth 是否站在同一边

这时你再去改配置，才是在改设计，而不是只是在调命令顺序。
