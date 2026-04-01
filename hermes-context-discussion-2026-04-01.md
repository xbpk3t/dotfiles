# Hermes Context Discussion 2026-04-01

## User

```text
# AGENTS.md instructions for /Users/luck/Desktop/dotfiles

<INSTRUCTIONS>


## NixOS 模块约定

- 对于 `modules/nixos/base` 里的“能力型模块”，优先只定义 options 和实现本身，不要再为了 `vps`、`homelab` 之类角色额外创建只包含 `enable = true` 的薄包装模块。
- 角色是否启用某个能力，优先直接在对应 `hosts/<name>/default.nix` 里声明；如果后续需要自定义参数，也直接在 host 层处理。
- 遇到容易和上游 NixOS 选项混淆的模块名时，命名要尽量体现语义边界；例如区分 `systemd Manager watchdog` 与 `services.watchdogd`。


## pkgs

用来存放自己打包的一些pkg


## Notice

注意修改代码，不要轻易修改 `docs/` 里的文档内容；当前 `docs/` 采用按 topic 分目录的扁平结构，以各 topic 下的 `README.md` 与按日期命名的 review 文档为主。

</INSTRUCTIONS><environment_context>
  <cwd>/Users/luck/Desktop/dotfiles</cwd>
  <shell>zsh</shell>
  <current_date>2026-03-30</current_date>
  <timezone>Asia/Shanghai</timezone>
</environment_context>
```

## User

```text
https://github.com/NousResearch/hermes-agent


按照我的理解，这玩意就是自动提取 skill，并在下次遇到类似任务时，自动复用skill，这样就可以持续迭代。是吗？


其实核心思想跟我也是不谋而合，我也是为了让AI编程可以有更充分的 context，所以做了 @docs/ 里面这么多 review doc，基本上也都是我觉得有价值的一些review


---

你可以看一下我之前写的一点相关想法：


    本周比较大的一个收获。

    原话如下：“这次处理，AI时代，堆积自己的项目文档，非常有利于高效决策，写下之前是怎么想的？为什么做出这个决策？基于什么制约因素、个人偏好？当时做了什么判断？之后的复盘？现在这些问题是否仍然存在？”

    拓展来说，是个日常workflow的迁移，有了这些docs后，很多问题，直接在codex里提问，codex本身可以直接引申我们的上下文，来获得更有价值的回答（而非直接在网页提问，要不需要手动写入大量context，效率很低，要不就会获得大量“信时比”很差的内容，需要自己再花费大量时间筛查、甄别、recall、内化，整个流程就会很长）

    ## 注意

    - 0、其实这个 docs（也就是项目文档），是从 record -> blog 延伸出来的。这条线的逻辑是，如果某条record的内容太长，放在record里就会很臃肿，不便维护。所以选择放到blog里，通过url引用回record，但是写blog又过于耗时（因为是要展示给别人看的，所以总是过于重形式而轻内容），进而决定直接把这些文档跟项目放到一起，就可以实现我上面所说的效果。再做出某个决策时，可以让AI仔细阅读之前的 review docs，以便做出符合当前情况的决策。并且在完成某个功能后，也可以直接让AI来直接生成文档，自己则只需要在doc开头写个TLDR（作为自己的理解，进行记录）即可。
    - 1、之所以没直接放到dotfiles的record里，就是因为这是个方法论，而非只是与某个repo有关。

    本文也可以作为本周复盘，因为本周确实也就做了这些事情。另外，相当一点很重要的事情：

    ---

    ## 拓展

    在跟grok聊天后，有了一些新感悟：

    核心洞见是：在 AI 时代，文档不再主要是给人看的，而是先给 AI 看，再给人看。
    这带来几个关键变化：

    - 0、文档的读者优先级反转：
    - 1、文档的写法原则建议（推荐你固定下来）：
    - 2、AI 使用 workflow 优化：


---

我真正想问的是：你觉得我是否有必要安装这个 hermes?
```

## Assistant

```text
我先看一下 `hermes-agent` 项目本身的 README / 设计描述，再对照你现在这套 `docs/review` 工作流判断它和你现有方法是互补还是重复。
```

## Assistant

```text
不完全是，但你的理解抓到了一半重点。

`Hermes Agent` 的核心不是“自动提取你现有文档里的 skill”，而是把 agent 自己做事时积累出来的“可复用流程”沉淀成 skill。官方描述里更接近这句话：它有一个 built-in learning loop，会“从经验创建 skill、在使用中改进、搜索过去会话、跨 session 保留 memory”([README](https://github.com/NousResearch/hermes-agent), [Skills System](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills/), [Memory](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory/))。
也就是说：

- 你的 `docs/review` 更像“高质量项目上下文 / 决策记录 / 约束说明”
- Hermes 的 skill 更像“把一个反复出现的操作流程，封装成程序性记忆”

这两者是互补关系，不是替代关系。你现在这套方法论本身是对的，而且其实已经踩中了 Hermes 里 `Context Files` 的思路：`AGENTS.md` 这类文件会被自动加载进 prompt，作为项目长期上下文([Context Files](https://hermes-agent.nousresearch.com/docs/user-guide/features/context-files/))。从这个角度说，你现在做的 `docs/` 和 review 文档，价值并不比 Hermes 的“自动技能”低，甚至对“做正确决策”更关键，因为那是 why，而 skill 更多是 how。

所以回到你真正的问题：`你有没有必要安装 Hermes？`

我的判断是：`大概率没必要立刻装。`

原因很简单：

1. 你当前最大的优势已经有了
   你已经在 repo 内积累了高价值 context，这对 Codex/Claude 这类代码 agent 非常重要，而且是更稀缺的资产。Hermes 不会替你自动产出这类高质量判断文档。

2. 你的痛点看起来不是“不会复用流程”，而是“如何让 AI 更充分理解项目历史和决策”
   这件事上，`docs/review + AGENTS.md + repo 内上下文组织` 比引入一个新 agent 框架更直接。

3. Hermes 会引入一整套新运行时和新心智负担
   它不只是 skill 系统，还包括 memory、gateway、cron、subagent、toolsets、跨平台消息入口等([README](https://github.com/NousResearch/hermes-agent))。如果你现在主要在本地 repo 里和 Codex 协作，这套东西很可能偏重。

但如果你有下面这些明确需求，那就值得试装一个小范围 pilot：

- 你想要“跨 session 持续记住你和项目”的 agent
- 你希望 agent 把常做的多步流程自动固化为 slash skill
- 你想让 agent 脱离 IDE/终端，在 Telegram/Discord/服务器上长期运行
- 你希望它自己做 schedule / automation / delegation

所以更实用的结论是：

`如果你的目标是“把 repo 文档变成 AI 的高质量上下文”，继续强化你现在这条路，比安装 Hermes 更值。`
`如果你的目标升级成“养一个长期在线、会积累 procedural memory 的个人 agent”，那 Hermes 值得试。`

另外纠正一个关键点：
`Hermes 不会自动把你 docs 里的 review 文档直接变成 skill。`
更合理的分工应该是：

- `docs/review` 存决策、约束、偏好、复盘
- `AGENTS.md` 存执行规则
- Hermes memory 存短小稳定事实
- Hermes skill 存反复验证过的操作流程

如果你愿意，我下一步可以直接基于你这个 `dotfiles` 仓库，给你一个更具体的判断：
“按照你现在的工作流，Hermes 值不值得引入，以及如果引入，应该只引入它的哪一部分。”
```

## User

```text
我想了一下，其实 hermes 相较我现在的这套方案，两点区别：1、更自动化。2、feats更丰富。会有 memory, skill 这些区分，而非我这个只有 context files，是吗？


---


另外，还有一个问题他这个 hermes 是天然跟 codex，claude, glm 之类的这些零配置，即可一起协同使用吗？还是说实际上我们需要以 hermes 作为入口来使用 codex 之类的 model? 具体是怎么个情况？


---


最后，我还有哪些 unknown unknown 问题？
```

## Assistant

```text
我先核对一下 Hermes 的文档里关于 `memory / skills / context files` 和它与外部模型、CLI 的集成方式，避免凭印象误导你。
```

## Assistant

```text
是，基本可以这么理解，但我会把差别说得更精确一点：

你现在这套更像是 `static project context`。
Hermes 是在这之上再加三层：

- `Context files`：项目规则、架构、约束。这个和你现在最接近，Hermes 也会自动加载 `AGENTS.md`，而且支持递归加载多个层级的 `AGENTS.md`([Context Files](https://hermes-agent.nousresearch.com/docs/user-guide/features/context-files/)).
- `Memory`：小而稳定的长期事实，比如“用户偏好”“环境事实”“项目长期约束”。它是有硬上限的，`MEMORY.md` 大约 2200 chars，`USER.md` 大约 1375 chars，不是无限知识库([Persistent Memory](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory/)).
- `Skills`：按需加载的操作性知识，偏“怎么做”，而不是“项目为什么这样做”。Hermes 的 agent 还能自己创建/修改 skill，把成功过的复杂流程沉淀下来([Skills System](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills/)).

所以你说的两点是对的：

- `更自动化`：对，尤其是 memory、session search、skill 管理、自动化任务这一层。
- `feats 更丰富`：对，而且不是只有 context file，而是做了分层：`context = 静态规则`，`memory = 稳定事实`，`skill = 可复用流程`，外加 `session search = 历史会话检索`([Persistent Memory](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory/)).

但要补一句：
`Hermes 不是天然比你的方案“更懂项目”。`
它只是把“长期上下文管理”拆得更细、更自动。你那些 `docs/review` 里沉淀的判断、制约、偏好，仍然是更高价值的材料。Hermes 并不会自动把这些高质量思考等价转化成同质量的 memory/skill。

关于你第二个问题，结论是：

`Hermes 不是零配置协同调用 Codex CLI / Claude Code CLI 的那种壳；它更像是一个独立 agent runtime，自己接模型。`

更具体地说：

- 它支持很多 provider，包括 `OpenAI Codex`、`Anthropic`、`GitHub Copilot`、`GLM/z.ai`、`Kimi`、`OpenRouter`、以及任意 OpenAI-compatible endpoint([Configuration](https://hermes-agent.nousresearch.com/docs/user-guide/configuration/)).
- 文档明确写了，`Codex` 这边是通过 `ChatGPT OAuth` 做 provider，Hermes 会把凭据存到自己的 `~/.hermes/auth.json`，并且“可以导入已有的 `~/.codex/auth.json`”，但“不需要安装 Codex CLI”([Configuration](https://hermes-agent.nousresearch.com/docs/user-guide/configuration/)).
- 对 `Anthropic`，它也会自动读取 Claude Code 的 credential files，如果你本来就在用 Claude Code，可以复用认证([Configuration](https://hermes-agent.nousresearch.com/docs/user-guide/configuration/)).
- CLI 入口是 `hermes` / `hermes chat`，也就是说实际使用时，通常是“以 Hermes 为入口”，而不是“继续用 Codex CLI，只是顺手挂 Hermes”([CLI Interface](https://hermes-agent.nousresearch.com/docs/user-guide/cli/)).

所以答案是：

- `不是那种无感地嵌进 Codex / Claude / GLM 原生工作流`
- `而是 Hermes 自己当 agent 宿主，再把 Codex/Claude/GLM 当后端模型提供者`

如果你问“那我能不能继续用 Codex，同时把 Hermes 当补充层？”
理论上可以部分复用认证和部分复用上下文文件，但交互主入口仍然会分裂成两套：

- 一套是你现在的 `Codex + repo docs/AGENTS.md`
- 一套是 `Hermes + memory/skills/session history`

这就是你现在最大的 `unknown unknown` 之一：`双系统分叉`。

我觉得你现在真正要警惕的 unknown unknown 有这几个：

- `记忆污染`
  Hermes 的 memory 很小，skill 会增长，session search 也会把旧讨论捞回来。问题不是“记不住”，而是“记住了过期/错误/局部最优的东西”。

- `procedural memory 可能固化错误流程`
  skill 一旦由 agent 自动沉淀，它可能把“某次碰巧能跑通的方法”当成长期 best practice。你现在的 review doc 往往有 why，而 skill 往往只有 how。

- `两套知识源冲突`
  你的 `docs/review`、`AGENTS.md`、Hermes memory、Hermes skills，可能对同一问题给出不同结论。届时谁是 source of truth，需要你事先定。

- `检索成功 != 理解成功`
  Hermes 能更容易“找回”历史，但找回不等于正确抽象。很多真正关键的东西仍然需要你写成高密度、结构清晰的文档，而不是指望 agent 从历史轨迹里自动蒸馏。

- `工具链和模型耦合`
  文档里提到很多能力依赖 auxiliary model、toolsets、MCP、browser、web extract 等，实际效果会受 provider、模型工具调用能力、上下文长度判断影响([Configuration](https://hermes-agent.nousresearch.com/docs/user-guide/configuration/), [Tools & Toolsets](https://hermes-agent.nousresearch.com/docs/user-guide/features/tools/)). 这意味着“功能多”也带来更多失配点。

- `运维和安全面扩大`
  Hermes 不只是聊天，还能 terminal、browser、cron、delegation、MCP([Tools & Toolsets](https://hermes-agent.nousresearch.com/docs/user-guide/features/tools/), [MCP](https://hermes-agent.nousresearch.com/docs/user-guide/features/mcp/)). 一旦真长期运行，它就不是一个“配置增强器”，而是一个有执行面的 agent 系统。

所以如果我给你一个很实用的判断：

`你现在最缺的不是 Hermes 这种 runtime，而是把你现有 docs 体系进一步“结构化”，让 agent 更稳定地取到。`

比如优先做这几件事，收益可能比装 Hermes 更高：

- 把 `docs/review` 里的文档按固定模板写：`背景 / 当时约束 / 方案对比 / 结论 / 何时失效`
- 在 repo 根 `AGENTS.md` 里明确：哪些文档是高优先级决策依据
- 给 review docs 加少量 frontmatter/tag，方便 agent 或脚本检索
- 区分 `长期有效约束` 和 `阶段性判断`

如果你愿意，我下一步可以直接帮你做一件更落地的事：
基于你这个 `dotfiles` 仓库，设计一套“比 Hermes 更适合你当前工作流”的 `docs + AGENTS.md + review metadata` 组织方案。
```

## User

```text
<environment_context>
  <shell>zsh</shell>
  <current_date>2026-04-01</current_date>
  <timezone>Asia/Shanghai</timezone>
</environment_context>
```

## User

```text
可以把我们上面的所有chat，类似于导出的效果，完全 1:1 地放到一个 md 文件里吗？放到项目根目录
```
