---
title: AI时代编程：从手写实现到抽象、编排与验证
type: review
date: 2026-03-26
updated: 2026-03-30
unlisted: false
tags:
  - LLM
  - AI
  - coding
  - engineering
  - workflow
summary: 讨论 AI 时代编程范式的变化，以及程序员如何把重心从手写实现转向问题定义、上下文组织、验证闭环与能力提升。
---



:::tip[TLDR]

从


:::


### Pre-requirements



:::tip


本文算是有一定，知道并熟练使用 MCP, skills, agent 等AI工具等常用功能

1. AI 为什么让“写代码”更容易了。
2. 但为什么同时又让“把事做对”更难了。
3. 真正的分水岭不在会不会用工具，而在于会不会定义问题、组织上下文、设计验证。
4. 所以 AI 时代程序员的核心能力，从“手写实现”转向“抽象 + 编排 + 验证 + 迭代”。
5. 最后再落到：怎么用 AI 提高效率，以及怎么用 AI 反过来提升自己的编程能力。

:::

![AI-agent-basic-concepts](https://cdn.lucc.dev/works/LLM/LLM/AI-agent-basic-concepts.webp)





```markdown
Most people think Skills and MCP are the same thing.
They're not. And confusing them is costing you
weeks of wasted architecture decisions.

I just mapped the entire Agentic AI extension stack
on a whiteboard — here's the breakdown:

𝗦𝗸𝗶𝗹𝗹𝘀

Reusable knowledge modules that agents load on-demand.
The agent scans metadata first, then loads full instructions
only when relevant. This is called Progressive Disclosure —
it keeps your context window clean while giving agents
deep domain expertise when they need it.
Think of them as training manuals for AI.

𝗠𝗖𝗣 (𝗠𝗼𝗱𝗲𝗹 𝗖𝗼𝗻𝘁𝗲𝘅𝘁 𝗣𝗿𝗼𝘁𝗼𝗰𝗼𝗹)

The universal connection layer between agents and external tools.
Standardized protocol — like USB-C for AI.
10,000+ MCP servers in the ecosystem today.
Now governed by Linux Foundation's Agentic AI Foundation.
If Skills teach you to cook, MCP gives you the kitchen.

𝗦𝘂𝗯𝗮𝗴𝗲𝗻𝘁𝘀

Independent agent instances running in isolated context.
They can use a different model, different tools,
different permissions than the parent agent.
Like specialized team members with their own workspace.
You delegate. They execute. They return summaries.

𝗛𝗼𝗼𝗸𝘀

Deterministic scripts that fire outside the agent loop entirely.
Pre-tool, post-tool, on-edit, on-notification triggers.
The LLM does NOT control these. Pure event-driven automation.
Think of them as tripwires — when X happens, do Y. Always.

𝗖𝗟𝗔𝗨𝗗𝗘. 𝗺𝗱

Always-on project context loaded every single session.
Your conventions. Your patterns. Your team preferences.
The sticky note permanently on your monitor.

𝗣𝗹𝘂𝗴𝗶𝗻𝘀

The packaging layer that bundles everything above —
Skills + Hooks + Subagents + MCP configs
into one installable, shareable unit.

Here's what most architects miss:

These are not competing approaches.
They are layers that stack:

Skills = WHAT to know
MCP = HOW to connect
Subagents = WHO does the work
Hooks = WHEN to automate
CLAUDE. md = WHERE you ground it
Plugins = HOW you ship it

The real power is in the combination:

CLAUDE. md loads project context
→ Skill provides domain expertise
→ MCP connects to external systems
→ Subagent executes in isolation
→ Hook automates the handoff
→ Plugin packages it all for the team

If you want to excel at building agents in 2026, stop picking one layer over another. Learn to orchestrate all six together. That's what separates demo agents from production agents.

Which layers are you actually using today?
```






## 基本认知





*[意识到一个ai的严重的问题 - 开发调优 / 开发调优, Lv1 - LINUX DO](https://linux.do/t/topic/2066642/31)*



```markdown
其实简单来说，现在的AI有几个已知问题

谄媚倾向 (偏好): 因为RLHF训练就是偏好回答问题，用户说什么都是对的
自动补全 (幻觉): 模型将不知道内容的也直接生成，预测下个词而跳过了推理链
引用伪造 (幻觉): 预训练数据的内容，当成有实际根据、连结的来源
锚定效应 (幻觉): 用户强烈暗示，提示的内容，模型会当成已知的概念来进行
在建构实际问题的过程中，其实有几个面向：

Unknown Unknown: 模型不知道自己不知道什么 —几乎无解，人也不知道，使用者要主动避开这些问题
Known Unknown: 从推理链/MCP等调用，可以猜出来未知的东西，知道要进行推理
实际上，现在最顶级的AI可以做到

挑战你的内容: 可以找出你的输入，和模型训练资料不对齐和不正确，以及你的提示的逻辑跳跃和不一致
透过提示词，可以一定程度缓解：谄媚倾向、锚定效应
识别你的未知: 能从你的输入中，分辨你哪个方向认为是未知，哪个是已知
透过提示词，可以一定程度缓解：自动补全；不能缓解模型本身的Unknown Unknown
知道连结是伪造的: 利用MCP/ Web-Fetch实际获取资料
透过Tools, 提示词，可以一定程度缓解: 引用伪造
但是，Default状态下，只要你不做任何Prompt处理，不给工具，

这些模型厂商是不会自动帮你解决的，大部分人是用来Coding+确认想法，让模型当杠精很烦，

所以真的能把AI用来当成学习工具的，很少很少，大部分的人现在都是知识的搬运工。

备注: 纯手Key，来自个人经验
```



```markdown
  ## 1. AI 时代编程的真正变化是什么

  放在最前面，作为总论。
  可写：

  - “写代码”被压缩成了更便宜的环节
  - “定义任务”和“验收结果”变成更稀缺的能力
  - 程序员角色从 coder 变成 architect / reviewer / orchestrator

  ## 2. LLM 悖论：记得更多，却理解得更少

  这个你已经有素材了，建议单独成节。
  可写：

  - LLM 擅长局部补全，不天然擅长全局抽象
  - 人脑记忆差，反而逼自己做压缩、抽象、归纳
  - 所以 AI 很强，但缺少“自己停下来重构问题”的能力
  - 这解释了为什么 AI 常常“看见树木，看不见森林”

  ## 3. AI 编程为什么反而对人要求更高

  这个是全文核心节。
  可写：

  - 你要会判断需求真假边界
  - 你要会拆任务，而不是直接丢一句“帮我实现”
  - 你要会识别幻觉、伪完成、局部最优
  - 你要有足够基础，才能知道 AI 哪里在胡扯
  - AI 放大的是人的上限，也放大人的短板
```


LLM悖论：完美记忆+泛化能力差 -> 人类记忆力差是feat，而非bug -> 记不住，大脑进入抽象模式，“看到森林而非树木”

人类则是 记忆力差，泛化能力（抽象能力）强






## 决定用 CE替代


[xbpk3t/ce-codex](https://github.com/xbpk3t/ce-codex)








## 怎么用AI工具来提高开发效率？

:::tip

***从 SuperPowers 切换到 gstack + CE***。另外，暂时不考虑使用 ``



:::


要冷静！要冷静！要冷静！不要追新！

也是写了8、9年的老鸟了，其实没必要这么FOMO，之前追新浪费了多少时间也是历历在目，也没必要说什么“这次不一样”、“这个技术不一样”


[夜读蛮学（二）——栓 - 知乎](https://zhuanlan.zhihu.com/p/1889881117437428531)

栓！人要拴起来，LLM更要拴起来！


要把agent“拴起来”，



最终方案会是什么样子的？

我猜想最终的context大概率会放在remote (而非local)，否则你本地到时候 100行代码，3000行文档，本地一搜某个字符串，乱七八糟全是文档，可维护性无论对于coder还是model都很差，

跟 https://linux.do/t/topic/1918400 这个帖子的理解差不多

https://x.com/dotey/status/2042324560700154312 最终主流 agent 一定会内置这些功能


https://x.com/dongxi_nlp/status/2041954843107979356



https://linux.do/t/topic/1906915/30



```markdown
将提示词工程和上下文工程再加上外部Agent编排器打包一下，就是harness Engineering ，一点点外延而已，大部分人跟风吹吹概念，工程落地的少之又少


---

Harness Engineering 其实可看作 AI 工程领域提示词工程 、上下文工程之后，第三次迁移的工程重心。
一开始，大家主要靠 Prompt Engineering 提升效果，通过不断打磨提示词，让模型更准确地理解任务、输出更符合预期的结果。后来随着 LLM 能力持续增强，模型对自然语言意图的理解已经足够强，很多时候不再需要特别精细、结构化的 prompt，也能取得不错的效果。

再往后，优化重点逐渐转向 Context Engineering：核心问题变成了，如何在有限的上下文窗口里，更高效地组织信息、调用记忆、补充背景，从而尽可能榨干模型能力。本质上，是在“有限注意力”条件下追求效果最优。现在上下文窗口越来越大，单纯优化 context 带来的收益已经开始接近边际递减。

严格来说，Harness Engineering 并不是什么全新的概念 ，最近Claude Code代码泄露才让这个概念突然有热度。大家开始意识到：LLM 本身能力已经很强，现在最有性价比的优化，不再只是抠 prompt 或 context，而是围绕模型外部的工具、流程、执行框架、反馈闭环等进行系统性设计。


```

```markdown
2026 年 “Harness Engineering” 这个词要火。

“Harness” 这个词，字面意思是“马具”，就是套在马身上、让人能控制马匹方向和力量的那套装备。

用在 AI 编程的语境里，它的比喻再贴切不过：AI Agent 就像一匹动力十足但不太守规矩的马，而 Harness 就是那套让它既能跑得快、又不会跑偏的缰绳和马鞍。

过去三年，三个阶段：

1. Prompt Engineering（2023-2024）：关注“怎么跟 AI 说话”

精心设计一段提示词，希望模型给出理想输出。Prompt Engineering 是优化一次性的输入-输出对。

局限很明显：一条消息能塞的信息有限，任务一复杂就失控。

2. Context Engineering（2025）：关注“给 AI 看什么信息”

不再只盯措辞，而是设计整个信息环境：系统提示、对话历史、记忆、RAG 检索结果、工具调用输出。

3. Harness Engineering（2026）：关注“构建什么环境让 AI 工作，这个环境如何保证它的产出是可靠的”

比 Context Engineering 更进一步，不仅管理输入给模型的信息，还包括模型之外的整个执行环境。

现在问题是，“Harness Engineering”中文怎么说？
```



---


```markdown
https://linux.do/t/topic/1906915/15
---

harness和prompt提示词、context engineering上下文工程和skill等概念的发力方向都是同一个，就是对大模型进行有效约束。但是采取的策略不同，力道也有差别。中文里形容程度的词一般都比较明显，强弱，很强很弱。但是，英文里程度词花样特别多，切入的角度也有差别。总而言之，harness不是凭空来的，跟它的前辈大方向类似，技术细节上有革新也就不难理解了。很有可能，以后又出来一个比harness更强的词，也不必大惊小怪就是。


```


```markdown
GStack 也把 Compound-Engineering 的学习能力集成进去了。没办法，当前 Harness Engineering 说白了就是在大规模做实验，那些 Star 极高的框架就是「实践中被发现在当前模型能力下有效的方法」

这些方法本身没有任何门槛，谁都可以借鉴。这种互相借鉴势必会一直持续，直到大家都趋同为大而全的框架。

---
這東西只有 office hours跟 plan ceo review 可以用

---
同感，harness 现阶段就是自动化试错。我搭了个编排服务器做 auto PR review + 任务分发，experiment → evaluate → iterate 循环跑起来效率完全不一样


```


```markdown


最近在对比使用三大harness skill：
Superpower: https://github.com/obra/superpowe
rs

Compound Engineering: https://github.com/EveryInc/compo
und-engineering-plugin

Gstack: https://github.com/garrytan/gstack


每个人有不同的喜好和偏向啊，我的感受如下：
首先，这三个skill本身是在解决同样一个问题，AI Agent在执行任务，尤其是写代码的时候容易跳过规划，质量不稳定，没有一个固定的workflow来限制它。但这三个skill又有不同的思维模型和侧重点：

Superpower：强调流程纪律，每一轮会从spec -> plan -> 拆解任务 -> 执行任务 -> 测试和review -> 提交。优点是流程控制的很好，缺点是小任务时间按这个走很长，需要授权的次数多，消耗token。

CE：强调知识复利，重点是给 AI 装记忆，错过的东西下次不再犯。/ce:compound 会把历史错误给沉淀下来。另外/ce:ideate 可以针对性提出改善建议，并会对优先级排序，筛选掉不重要的improvements。但是我实际的感受是，这些改善点优点不痛不痒。

gstack：最大的亮点是YC的知识和评判标准，对于产品和idea的打磨，让AI对你进行灵魂拷问。更新的版本也支持知识沉淀，未来使用。

我的感觉是，如果是大工程用gstack来进行产品和idea打磨，superpower来执行。


```


```markdown
总结：
1. Superpowers 规范化执行流程(怎么做)，核心技能：Brainstorm, Plan, Execute, Review.
2. gstack 产品视角决策做什么+质量检验，核心技能：Office Hours, CEO Review, Eng Review, QA.
3.CE 知识沉淀与复用.
```


harness engineering 只是一个统称，大概分为两类：skills 和 agent

前者包括 `SuperPowers`, `gstack`, `CE` 这些

后者则是 `hermes-agent`, `OMO (oh-my-opencode)`, `OMCX (oh-my-codex)` 之类的


长期来看




```markdown
Superpowers 的爆火不是没道理。它解决了一个真实需求，即结构性地使用 AI

但这周深度用下来，我已经开始用 Compound Engineering 替代了 Superpowers，跟 gstack 组成更完整的 harness

核心差距主要是 Superpowers 做完就完了，CE 做完还能 compound，把踩过的坑变成所有未来 session 都能搜到的知识。补齐了self-improving agent的拼图

备忘录 vs 知识库，线性 vs 指数


---
是的 而且我认为当前情况下TDD对于agent来说是一个很好的模式 再加上harness治理和我自己的一些技能 我目前生产项目就是100%AI工作流 并且每次都是精准实现


---

确实，现在/office-hours和/plan-eng-review质量很满意，就是之后到/ship之间总感觉差了点


---
「备忘录 vs 知识库，线性 vs 指数」这个切法准。我自己跑 Claude Code harness 的体会是，compound 需要三层才真正转起来：约束规则（CLAUDE.md）、积累记忆（worklog + agent-memory）、反馈循环（每次纠正自动更新规则）。

大多数 harness 只做了第一层——写了一堆规则但不会自己演化。Superpowers 停在那里，CE 补了第二层。但真正的指数增长在第三层：agent 犯错后自己写新规则防止重犯。self-improving，不是 self-recording。


---
我是Superpower和Compound结合着用。我对Compound Engineering的软件开发流程很不适应吗， 就像不适应CC自带的Plan一样， 可能是用Superpower习惯了。 但Compound 作为knowledge base积累是必须有的， 尤其是在一个团队的情况下， 对于稳定输出结果很关键。
```




```markdown
这两天深度体验了 Hermes Agent，最大的感受就是 self-improving 是真的

你能明显感觉到它更主动，是在自主成长的

它的 skill 是自己在解决问题后自主积累的，不需要你多说一句话，反馈机制做的也很好，memory updated、skill saved，这些状态实时能看到，能直接感知到它在此刻成长

这是 OpenClaw 给不到的，Hermes 把这个过程透明化了

Hermes 的记忆是紧凑记忆+SQLite 搜索，相比于 OpenClaw 每次载入都要读一系列文档、消耗上万 token 比起来，Hermes 明显感知更轻、更快、更省钱

OpenClaw 我没直接弃用，但显然接下来我用 Hermes 会更多一些
```

很明显 hermes-agent 是跟 openclaw 对标的，而非。我也跟用不到什么 定时邮件、TG robot之类的



```markdown
绝大多数的人的OpenClaw可以放弃了
根本不用考虑，直接选择Hermes Agent

核心就是几点：
1.  记忆系统远远强于原生OpenClaw
2.  学习闭环，自动迭代能力强（自己创建/优化skill，定期 nudge 保存）
3.  部署能力灵活
```





```markdown
Hermes Agent 势头很猛，这几天推荐的人很多，可以关注一下。我自己安装试用了还可以。

Hermes Agent 是由 Nous Research 在今年 2 月底开源的 AI 智能体框架，上线不到两个月，GitHub 星标已经接近三万。这个项目被社区认为是 OpenClaw（龙虾）上线以来，第一个真正意义上的竞争对手。

两者都是自托管的开源智能体，都能接入 Telegram、Discord、Slack、WhatsApp 等聊天平台，都支持多模型切换，都走 MIT 协议。但设计哲学完全不同。

【1】龙虾是网关，Hermes 是引擎

OpenClaw 的核心是一个 Gateway（网关守护进程），负责统一管理会话、路由和渠道连接，像一个调度中心，把你的各种聊天应用连接到 AI agent。你可以理解为它是一个“多渠道个人助理操作系统”。

Hermes Agent 的核心则是 agent 自身的执行循环。它不是围绕“怎么把消息送到 agent”来设计的，而是围绕“agent 怎么变得越来越强”来设计的。官方管这叫 closed learning loop（闭环学习循环）。

【2】会自己写技能的 agent

这是 Hermes 最有意思的地方。当它完成一个复杂任务（通常涉及五次以上工具调用）后，会把整个过程沉淀成一份结构化的技能文档，存成 Markdown 文件。下次遇到类似任务，直接加载这份技能，不用从头解决。

更关键的是，这些技能在使用过程中会自我迭代。如果 agent 在执行技能时发现了更好的方法，它会自动更新技能文档。有 Reddit 用户反馈，agent 在两小时内自动生成了三份技能文档后，重复性研究任务的速度提升了 40%。

OpenClaw 也有技能系统，但主要依赖人工编写和社区贡献的技能市场 ClawHub。Hermes 这边等于把“写技能”这件事也交给了 agent 自己。

【3】记忆体系的差异

两者都声称有跨会话记忆能力，但实现方式不同。

Hermes 用 SQLite 数据库配合全文检索，把所有历史对话存下来，需要时通过搜索加摘要召回。它把记忆分成两层：一层是常驻的关键信息（写在 MEMORY.md 里，每次对话都带上），另一层是全量历史检索（容量无限，按需调用）。

OpenClaw 的记忆则是工作区里的 Markdown 文件，走的是“文件即记忆”的路线，通过语义检索工具来查找。在上下文压缩前会执行一次静默记忆写入，防止压缩丢信息。

简单说，Hermes 更像是给 agent 装了一个搜索引擎式的大脑，OpenClaw 更像是给它一个笔记本。

【4】安全思路也不一样

Hermes 搞了一套五层纵深防御：用户授权、危险命令审批、容器隔离、凭据过滤、上下文注入扫描。默认对高风险操作（比如执行终端命令、写文件）要人工审批，超时未批准就自动拒绝。

OpenClaw 这边则更强调信任模型和配置审计。它提供了 openclaw security audit 命令，可以一键扫描网关配置的安全隐患。但 OpenClaw 在安全方面的历史记录不太好看，今年 2 月被曝出多个高危漏洞，13.5 万个实例暴露在公网上，技能市场也有超过 300 个恶意技能被发现。

【5】要不要换或者选哪一个

如果你日常用的 Agent 已经顺手，没必要。如果你之前的龙虾主要是 claude code 的授权现在用不了可以试试这个，但不能保证继续用多久。如果喜欢折腾想试试不同的选择，也可以试试。

如果你想要一个“多渠道助理平台”，接入各种聊天工具，用社区现成的技能市场，OpenClaw 的生态更成熟，34.6 万星标不是白来的。

如果你更关心 agent 的长期进化能力，想让它用得越久越聪明，或者你是做 AI 研究的，需要生成训练轨迹、跑强化学习实验，Hermes 的架构更对口。它还内建了一个兼容 OpenAI API 的服务端，可以直接作为后端接入 Open WebUI 等第三方界面。

Hermes 跑在 5 美元一个月的 VPS 上就够用，也支持 Docker、SSH 远程、Modal 等 serverless 方案。安装只需要一行 curl 命令。
```







https://github.com/EveryInc/compound-engineering-plugin

https://github.com/mindfold-ai/Trellis

https://github.com/Yeachan-Heo/oh-my-codex






### SuperPowers -> 高效使用 AI 编程工具的工作流


其实这个workflow并非无中生有，从两方面来说


其实 [spec-kit](https://github.com/github/spec-kit)




```markdown
https://x.com/axtrur/status/1934135527206469994
---

开个经验贴总结下使用claude code的一些小tips：
1. 【Plan First】: 任务开始之前的Plan很重要，除了提示词描述好任务细节外，可以结合task-master对PDR进行任务拆解，描述好优先级和依赖关系，然后让claude code基于.taskmaster/tasks/tasks.json的规划进行开发
2. 【Create Sub Task】: 对一些任务开始之前的方案调研或者可以分拆分拆任务然后合并的需求，可以显示的让claude开启sub Task进行Deep Research或者子任务拆解
3. 【Iterate UI with Pupeteer】：对于设计图还原，可以让Claude code使用puppeteer MCP进行网页浏览、网页截图从而反复迭代，保证跟UI设计稿的一致性。
4. 【Context Auto Compact】:  Claude Code的机制注定上下文消耗很快，当任务上下文特别长但是又不想clear的时候，可以执行/compact 手动对进行上下文压缩
5. 【MCP自举】：当有些功能不满足时，可以让Claude Code开发对应的MCP然后调用claude mcp add命令进行自注册
6. 【Stage Early, Stage Often】：为了代码的测试、验证、回滚，可以配合Git进行迭代、验证、提交
7. 【Git Worktrees】: 有群友提到可以使用Git Worktrees让claude在同个git工程下同时执行两个不同的任务（这个尚未验证）
```




### 主流方案对比 (SuperPowers, gstack, spec-kit)




***https://x.com/xxx111god/status/2038093217782997144***

gstack 是啥？





---

确实日常来说就这几类操作

```markdown
https://github.com/tw93/waka
https://x.com/RookieRicardoR/status/2041065825592066207
---


把我自己常用的 Skill Release 成一个新玩意叫 Waza，在日语中是 技（わざ） 的意思，常用于武术领域的招式，第一次开源一个没有代码只有 md 的产品，在没有 AI 的年代对于程序员而言是很羞耻的。

之前 Superpowers 出来的时候，我安装一次就卸载了，感觉太重了，不是很适合我，会有不少人给我推荐 “你知道 Superpowers 吗？这个都不用那你就不潮流了，非常牛逼”，后面发现了 gstack，好了不少，但还是太多了，还是不习惯，我期待简单好用，同时清楚它在做什么。

所以我按自己的习惯做了 Waza，对我而言装上这一套就够了，其他 skill 不用再折腾，不多不少刚好够用，后面有新的迭代可以持续优化下去。8 个 skill 对应我认为在 AI 时代一个好的工程师应该具备的 8 个能力：

1、会思考，AI 写代码很快，但方向错了越快越远，好的工程师在动手前会先质疑问题本身，压测方案，脑子里有清晰的架构再让 AI 去执行，/think 就是把这个习惯固定下来。

2、会设计，做产品不只是把功能实现了，AI 生成的东西很容易千篇一律，好的工程师对交付物有审美要求，出来的东西要有明确的设计方向，/design 做的就是这件事。

3、会排查，AI 改 bug 最容易陷入”改了试试”的循环，好的工程师遇到问题会系统化定位，确认根因再动手修，一次到位，这个习惯我沉淀成了 /hunt。

4、会检查，AI 生成的代码更需要人来把关，合并前先审一遍 diff，能自动修的修掉，需要判断的归拢到一起，用证据验证而不是凭感觉收工，这个是 /check。

5、会阅读，好的工程师习惯读一手资料而不是二手总结，把 URL 或 PDF 转成干净的 Markdown 直接进工作流，/read 做的就是这件事。

6、会写作，技术再强，写不清楚别人就接收不到，好的工程师能把学到的、想表达的东西清晰地传递给对应的受众，/write 帮你把这一步做好。

7、会学习，AI 时代技术迭代更快，进入一个陌生领域不是刷几篇文章就完了，而是收集、消化、提纲、初稿、打磨、发布，用输出驱动学习，/learn 就是这套流程。

8、会维护，好的工程师不只关注业务代码，工具链本身也需要体检，CLAUDE.md、rules、hooks、MCP 这些配置感觉不对的时候跑一下 /health 就知道问题在哪。
```




### 相关使用问题


https://linux.do/t/topic/1836688










### harness


***https://x.com/kevinma_dev_zh/status/2041358398827200566***


https://github.com/deusyu/harness-engineering

https://github.com/walkinglabs/awesome-harness-engineering



***[什么是Harness？不就是Agent的Infra嘛_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1nyQGBaEKW/?vd_source=f93a90ecd1f4fbda93651d654ff4c882)***


[(1) 宝玉 on X: "推荐阅读若石写的这篇博客：模型不是笨，是 Harness 没配好 AI 智能体跑十步就崩，很多人第一反应是模型太蠢，但这篇文章却给出另一个视角：不是马不行，是缰绳没拴好。 文章提出的 Harness Engineering，你可以理解成给 AI 模型戴上安全带、装上安全气囊的工程实践。 https://t.co/zQin9ri0bV" / X](https://x.com/dotey/status/2044660793153655205)



---


https://github.com/NousResearch/hermes-agent



简单来说吧，我如果用 hermes agent


平时使用时应该直接用哪个cli？hermes? codex? 如果是 hermes 的话，是否存在其工具本身不好用的问题？以及 他是怎么把task扔给codex的？

其实按照我的理解，就是内置了一套方法论的 OpenCode?


但是我感觉他最核心的机制，其实本身用一套 skills 也能替代掉啊？



```markdown
你的理解**基本正确，但还差了一点关键**。

**Hermes Agent 确实内置了一套“方法论”**（或者说一套哲学 + 流程），但它**不是简单的“带了方法论的 OpenCode”**，而是更深一层的东西。

### 1. 它跟 OpenCode（或类似 coding agent）的关系
- OpenCode（以及 Codex、Claude Code、OpenHands 等）主要是一个**执行引擎**：擅长读代码、编辑文件、跑命令、完成具体 coding 任务。
- Hermes Agent 则是一个**持久化的“AI 大脑/操作系统”**：
  - 它有自己的规划、记忆、自我评估机制。
  - 当遇到重度 coding 时，它会把任务**委托**给 OpenCode / Codex / Claude Code 等（通过内置的 `codex`、`claude-code` skill）。
  - 所以你可以把它看成 **“带方法论 + 记忆 + 学习闭环的协调者”**，而 OpenCode 是它常用的“执行手”之一。

很多人确实说：Hermes 像一个“升级版”或“带长期记忆的” coding agent 框架，但它的野心比单纯的 coding agent 大多了（它还能管 Notion、Linear、日程、Telegram 回复等）。

### 2. 你说的“最核心机制其实一套 skills 就能替代掉”——这个想法**只对了一半**

**Skills 系统确实是 Hermes 非常核心的部分**：
- Skills 就是可复用的“程序化记忆”（procedural memory）。
- 它能自动从一次复杂任务中提炼出 skill，保存到磁盘，下次直接调用。
- Skills 支持自我改进（用着用着发现哪里不好，就自动 patch）。

**但 skills 无法完全替代整个核心机制**，原因在于：

- **Closed Learning Loop（闭环学习）** 是真正核心：
  - 不只是“有 skills”，而是 **agent 自己会定期自我评估**（self-evaluation）。
  - 它会主动“nudge”（提醒/推动）自己把重要知识写进长期记忆（MEMORY.md）。
  - 复杂任务后自动创建/优化 skill。
  - 跨会话搜索历史 + 总结 + 构建“你是谁”的用户模型。
  - 这些是动态的、持续演化的过程，不是静态的 skill 列表能完全覆盖的。

简单说：
- **一套 skills** ≈ 你手动/半自动积累的工具箱（静态或半静态）。
- **Hermes 的 closed learning loop** ≈ 一个会自己思考、自己反思、自己进化工具箱的“活的系统”。

如果只有 skills 而没有这个学习闭环，Hermes 就会退化成一个普通的“工具调用型 agent”，长期使用后不会越用越懂你、越用越聪明。

### 实际感受区别
很多用户反馈：
- 纯靠 skills + 工具调用 的 agent，用一段时间后还是会“忘事”、重复犯类似错误。
- Hermes 因为有自我学习闭环，**用得越久越像私人助理**（知道你的项目习惯、代码风格、偏好等）。

当然，skills 是这个闭环最重要的产出物之一——Hermes 最牛的地方就是“把经验变成可复用 skill”的自动化程度很高。

**总结一句话**：
Hermes 不是“内置方法论的 OpenCode”，而是 **“一个会不断自我进化的持久 Agent 平台”**，其中 skills + 委托（codex/claude-code 等）是它的执行能力，而 closed learning loop 才是让它区别于其他 agent 的灵魂。

如果你觉得 skills 已经够用，那短期内确实可以主要依赖 skills。但长期来看，Hermes 最值钱的就是那个“自己长本事”的机制。

你现在是用它主要做 coding 吗？还是想用来做更广的个人助理/自动化？这样我可以更具体说说在你的场景下，skills 和 learning loop 哪个更重要。
```


---


```markdown
谈一下我的个人观点

Harness Engineering大概率也是不会有突破的
别说一年，10年也未必

马具工程想做的事，实际就是从1949年至今软件行业70多年来没解决的事情

永远说不清楚需求的甲方，文档写完就没人看的BA
拆不清楚任务的Leader，只会PUA和甩锅的PM

一切都是靠996的码农承担
这是一个悖论 👇
```



```markdown
最近一直在思考 Harness Engineering，架构约束、AGENTS.md、意图规范、自动化反馈回路，这些做法完全没问题，但总感觉有点模糊。后来发现，模糊不在做法本身，而是它没有说明白，它的出现是为了解决什么核心问题。

Agent 的协作有两个区间。Copilot 区间是人在 loop 的同步协作，你和 Agent 实时交互，每一步你都参与决策。Delegate 区间是人离开 loop 的异步委托，你把任务交出去，Agent 独立决策和执行，做完交回来验收。

Agent 能力在增长，能做的事越来越多，独立工作时间越来越长。一个跑几分钟的任务你可以盯着，一个跑两小时的任务你盯不住，也不应该盯。工作时间变长，你和 Agent 协作的方式就会自然地从 Copilot 区间滑入 Delegate 区间。

但同步和异步的工作方式，带来的挑战完全不一样。同步模式下你实时参与，随时能给出上下文进行纠偏，容错成本很低。一旦变成异步，任务定义不清 Agent 就跑偏，过程中出了问题没人拦，验收时一堆东西堆在一起 review。导致在产品设计上就需要不一样的思路。

所以核心矛盾是：Agent 因为能力增强，正在从同步模式转向异步模式。这种不可逆的趋势下，真正的题是怎么构建安全的异步委托机制，让这个转变可控。

Harness Engineering 就是在做这件事。它把整个系统反馈回路里的客观信号，编译器、类型检查、lint、测试、CI、线上日志、Sentry、可观测性平台，直接接到 Agent 面前，去掉人作为中间传递者的角色，让 Agent 自己读信号、自己闭环。

但除了客观信号，还有主观信号。方向对不对，命名好不好，方案该不该推翻，用户真正想要的到底是什么。这些判断只存在于人的脑子里，环境中没有对应的信号源，Harness 再完善也接不进去一个不存在的东西。

这是两个不同性质的问题。客观信号是工程问题，接上就行。主观信号是知识沉淀外化问题，它带来的是产品和技术上的双重设计挑战：如何让人或者组织自然、甚至无感地进行知识沉淀外化。难得多，但也是 Delegate 区间能不能真正持续扩大的关键。

还有一个有意思的现象：我们构建的异步委托机制越完善，Agent 异步工作就越安全，人需要介入的地方就越少，Delegate 区间进一步扩大。Agent 能力的增长在推，基础设施的完善也在推，两股力同向，Delegate 只会越来越多。

所以啊，今年会不会产品或者方法论，解决知识沉淀外化的问题呢🤔



---
感觉得有个自动进化的知识库，既能新增知识，也能对已有知识评判修改之前的记忆，感觉现在很多都是append，很少有update的
---

知识的 update 是个巨tm复杂的东西，新的知识，可能推翻旧的知识，甚至旧的知识结构。比如日心说，人类社会是通过接近无穷的人员和时间上的冗余，来消化这种范式变化。我是没想明白，咋有啥机制能够解决的。

---
Harness Engineering 就是在做这件事。它把整个系统反馈回路里的客观信号，编译器、类型检查、lint、测试、CI、线上日志、Sentry、可观测性平台，直接接到 Agent 面前，去掉人作为中间传递者的角色，让 Agent 自己读信号、自己闭环。
---
方向对不对，命名好不好，方案该不该推翻，用户真正想要的到底是什么。这些判断只存在于人的脑子里，环境中没有对应的信号源，Harness 再完善也接不进去一个不存在的东西。
```



### tricks

告诉 AI如何验证，而非哪里错了（输入、期望结果、实际输出）





```markdown
  ## 5. 不要告诉 AI 哪里错了，要告诉它如何证明自己是对的

  这节非常重要，值得单独展开。
  可写：

  - 错误反馈的低质量写法：“这不对，你再改改”
  - 高质量写法：输入、预期输出、实际输出、验证命令、失败日志
  - 把“挑错”升级成“定义验收标准”
  - 让 AI 跑测试、截图、lint、diff，而不是只改代码
  - “验证设计”是 AI 编程时代最关键的工程习惯
```



[(1) Shen Huang on X: "上周花了好几亿 token debug 一个 race condition，全失败。 后来受 Karpathy auto-research 启发，只加了一句话："把所有假设和证据写到 DEBUG.md。" AI 列了 5 个假设。其中第 3 个没有任何反对证据。 3 行实验 → 根因确认 → 5 分钟修完。 之前蛮干浪费的 token 比最后修 bug 多了 1000 倍。 https://t.co/RO5bEyhTz7" / X](https://x.com/ShenHuang_/status/2043469166418735204)






---



为什么 CLI 反而成了 Agent 时代最自然的接口？
为什么传统 SaaS 的 API 思路正在失效？
Workflow vs Agent，产品的“确定性”和“无限组合”该如何取舍？
为什么你会不知不觉中消耗更多内容，甚至更多 token？
以及——未来的软件，是不是只剩下“原子能力 + AI 组合”？



https://x.com/fkysly/status/2038923902135779762

test code 是真正的核心代码，才是护城河（参考之前cf用几天时间复制了一套nextjs，就是因为其测试代码也开源了） -> AI时代，可以有助于我们提高代码质量

https://www.ruanyifeng.com/blog/2026/03/weekly-issue-388.html



---




```markdown
25 条 Claude Code 最佳实践：

1. alias cc='claude --dangerously-skip-permissions' 加到 ~/.zshrc，省掉所有权限弹窗

2. 遇到 bug 别描述，直接 cat error.log | claude "fix"

3. 指令写成闭环："重构，跑测试，修报错，完成后结束"

4. Shift+Tab 进 Plan Mode，架构改动先列计划再动手

5. @文件路径 精准投喂，别让 Claude 自己去全库搜

6. !git status 这类命令输出自动进上下文，不用手动复制

7. 切换任务必 /clear，上下文堆久了输出质量悄悄变差

8. 纠错两次没对就重开，别撑着坏的对话线程继续修

9. /compact 时说清楚保留什么，裸跑容易丢关键上下文

10. 复杂问题加 ultrathink，Claude 会动态加深推理

11. "这个文件你觉得有什么可以改进的？" 适合探索陌生代码库

12. CLAUDE.md 每条问自己：没这句会出错吗？不会就删

13. 报错后说"更新 CLAUDE.md 确保不再犯"，规则越用越聪明

14. .claude/rules/ 设条件规则，TypeScript 规则只在 .ts 文件触发

15. 用 @imports
 引用长文档，别直接粘进 CLAUDE.md

16. .claude/skills/ 存特定知识，用时加载平时不占上下文

17. CLAUDE.md 管建议，Hooks 管红线，两者不要混用

18. PostToolUse Hook 绑 Prettier，文件改动后自动格式化

19. PreToolUse Hook 拦截 rm -rf 这类危险命令

20. claude --worktree feature-auth 创建独立工作区并行开发

21. 派 Subagents 去读文档，主会话上下文保持干净

22. .claude/agents/ 存预置 agent 配置，常用角色随时调用

23. 优先教 Claude 用 gh、sentry-cli，比 MCP 更省上下文

24. MCP 先装这四个：Playwright、数据库、Slack、Figma

25. /init 生成的 CLAUDE.md 是起点，之后删掉一半才是正确用法
```








#### zzz


[(1) 劳伦斯 on X: "一个冷门无人提的冷知识却又是程序员常识： Vibe Coding 的时候，一定要让 AI 写一个完整的可追溯的日志体系。 查问题省 token，还能提高 AI 的排查效率。 基本上看一眼日志、代码，基本就定位了。 https://t.co/mfyxhuelve" / X](https://x.com/LawrenceW_Zen/status/2044437995269591195)


#### Agent协作模式


[(1) 岚叔 on X: "Anthropic 出了一篇多 Agent 协作模式指南，总结了 5 种架构和适用场景。 总之不要让协调复杂度超过任务本身的复杂度，干货很足，分享总结如下： 1. Generator-Verifier（生成-验证） 一个 Agent 出活，另一个 Agent 审核。审不过就打回重写，循环直到通过。" / X](https://x.com/LufzzLiz/status/2043839678252761117)











### Agent对比（codex, cc）




[有点想放弃codex了，codex工程化能力缺陷太明显 - 搞七捻三 - LINUX DO](https://linux.do/t/topic/2061684)




```markdown
有个问题哈，是不是现在来说 cc从使用来说，确实是要比 codex好很多？那是否推荐在 cc里使用 GPT model? 会影响实际效果吗？
```


```markdown
我自己的判断是：

**不能简单说 CC 现在“明显比 Codex 好很多”，但如果你问“日常体感谁更像一个成熟的 coding agent”，很多人会更偏向 CC。**
原因不是 Codex 缺核心能力，而是两边的强项不同。Claude Code 现在已经把 **plugins、skills、subagents** 做成了一整套扩展体系，还支持把探索/规划/实现拆到不同 subagent 里；另外还有实验性的 **agent teams**，适合并行研究、并行调试、多人分工式任务。([Claude][1])

但 **Codex 也已经不是“能力不全”的状态**。官方文档里，Codex CLI 已经支持交互式 TUI、模型切换、截图输入、代码审查、subagents、web search、MCP、cloud tasks，以及比较明确的 sandbox 和 approvals 机制。它更像是 **“原生为 GPT coding agent 设计的工作台”**。([OpenAI 开发者][2])

所以更准确地说：

* **你更看重 agent 手感、长会话、任务拆分、插件化扩展**，我会更偏向 **CC**。这点是从它现在公开文档里的插件、subagents、agent teams 形态推出来的。([Claude][1])
* **你更看重 GPT 原生适配、安全边界、审批流、OpenAI 自家工作流**，我会更偏向 **Codex**。([OpenAI 开发者][2])

关于你第二个问题：

**我不太推荐把 GPT 当成 CC 里的主力模型。**

原因很直接。Claude Code 官方文档里，模型配置写的是通过 `/model`、`--model`、`ANTHROPIC_MODEL` 来选择模型；默认模型和别名解析也都是 **Opus / Sonnet / Haiku** 这套 Claude 家族。我没有在官方文档里看到 **把 OpenAI GPT 作为 Claude Code 一等公民 provider** 的说明。([Claude][3])

这就意味着：
**如果你在 CC 里用 GPT，通常不是“官方主路径”，更像兼容层/代理层/第三方接法。** 在这种情况下，**会影响实际效果**，而且影响往往不是“模型智力变差”这么简单，而是：

1. **agent 行为可能不稳定**：CC 的提示编排、subagent 委派、工具调用习惯，本质上是围绕 Claude 模型家族设计的；换成 GPT 后，计划风格、工具调用节奏、停止条件、输出结构都可能变。这个结论是基于 Claude Code 官方模型配置只面向 Anthropic 模型这一点做的合理推断。([Claude][3])
2. **高级能力不一定完全对齐**：尤其是你要用到 subagents、插件、hooks、复杂工具流时，兼容层通常最先出问题。Claude Code 的插件体系本身很丰富，但“丰富”不等于“对第三方模型天然稳”。([Claude][1])
3. **调参和排错成本更高**：出了问题时，你很难判断是 GPT 本身、兼容 API、还是 CC 的 agent 编排导致的。这个不是官方文档原句，而是很常见的工程后果推断。

所以我的建议是：

**主力这样选最稳：**

* **想用 Claude，就用 CC**
* **想用 GPT，就用 Codex**

这样最符合两边现在的“原生设计方向”。Claude Code 官方模型入口就是 Claude 系列；Codex 官方则明确支持在 CLI / IDE 里切换 GPT 模型，默认本地模型也是 GPT 路线。([Claude][3])

只有一种情况我觉得 **“在 CC 里接 GPT 也可以试”**：
你只是把它当成 **便宜/快速的副模型**，做一些低风险任务，比如简单问答、轻量搜索、草稿生成、非关键性重构建议。不要让它承担最核心的 agent loop。Claude Code 的 subagents 也正适合把不同任务路由给不同模型，这一点从其 subagent 设计能“按任务类型隔离上下文并控制成本”可以看出来。([Claude][4])

一句话结论：

**从“用起来爽不爽”的角度，CC 现在常常会更讨喜；但如果你本来就想主用 GPT，那别绕路，直接上 Codex，整体效果通常更稳。**
你要是愿意，我可以下一条直接给你一套 **“2026 年我会怎么选：CC / Codex / 混用”** 的实际工作流配置。

[1]: https://code.claude.com/docs/zh-CN/plugins "创建插件 - Claude Code Docs"
[2]: https://developers.openai.com/codex/cli "CLI – Codex | OpenAI Developers"
[3]: https://code.claude.com/docs/zh-CN/model-config "模型配置 - Claude Code Docs"
[4]: https://code.claude.com/docs/zh-CN/sub-agents "创建自定义 subagents - Claude Code Docs"

```


---

[(1) 宝玉 on X: "OpenAI 的 Agents SDK 最近做了一次重要升级，增加了两个关键功能：内置沙箱执行环境和模型原生执行框架（Harness）。这次更新的目标，是帮助开发者更容易地创建安全可靠、能长时间稳定运行的 Agent。 以前开发者使用 OpenAI 的模型来搭建 Agent" / X](https://x.com/dotey/status/2044474625510318235)







### skills




[(1) meng shao on X: "Agent Skills 设计的十个重要原则 十大原则指向单一纪律：沉淀！ 遇到重复任务，沉淀为 Skills。注意到有效的判断，沉淀如何做出它。发现模式，沉淀模式让系统识别它。 获得 100x 结果的人并非更聪明，没有使用秘密模型。他们只是无情地将工作沉淀为 Skills ——然后让这些 Skills https://t.co/adzS6rZEco" / X](https://x.com/shao__meng/status/2043311350374338897)




### 省token

[(1) Avi Chawla on X: "How to cut Claude Code costs by 3x (using Karpathy's context engineering principles)" / X](https://x.com/_avichawla/status/2046500537584218438)

***[(1) nash_su - e/acc on X: "非常有意思的研究，里面提到的项目都值得深入探索下，之前没仔细考虑过 memory 和 context 的差异，这个文章刚好作为切入点。" / X](https://x.com/nash_su/status/2044646757741793751)***








### Agent

[智能体社交革命：AI Agent是怎么来到你我身边的？ - YouTube](https://www.youtube.com/watch?v=JGiguIv6m8s)


[(1) 李继刚 on X: "日读论文： https://t.co/xdxU93Dk1j 为什么这两年模型没怎么变大，Agent 却突然能干活了？ 过去三年的故事很熟悉：参数一路堆上去，从十亿到万亿，GPT-4 Gemini DeepSeek 一层层盖。大家信 scaling law，信只要模型够大，它就能记住世界、规划长任务、和别人协作。这是「靠体重解决问题」的时代。 https://t.co/LtlncK0pvK" / X](https://x.com/lijigang/status/2042442044594139491)





### zzz



[一个偏门小观点：讨论为什么八股文是当下 Vibe Coding 版本答案 - 开发调优 - LINUX DO](https://linux.do/t/topic/2064369)

[(1) 阿绎 AYi on X: "说个暴论，这可能是今年对AI辅助开发影响最大的一次更新， TS大神@mattpocockuk Pocock刚刚给他的代码架构改进技能，加了一份只有37行的官方术语表， 要求所有AI输出必须严格使用里面的词汇，不能用component service API boundary这些烂大街的词，" / X](https://x.com/AYi_AInotes/status/2048071414054318378)




你觉得这两个tab里说的是不是一码事？


深入思考，然后给我一个综合判断

```markdown



从表面上看，这两个页面讨论的具体技术不同（一个是 Java 程序员常说的“八股文”，一个是 TypeScript 大神 Matt Pocock 的架构术语表），但**深入思考后，我认为它们核心逻辑上说的是极其相似的“一码事”**。

这两个观点都在探讨同一个深层命题：**在 AI 辅助编程（Vibe Coding）时代，人类如何通过“标准化语言”来约束和对齐 AI 的思考。**

以下是我的综合判断：

---

### 1. 核心逻辑的共性：从“术语”到“思考框架”

* **[LINUX DO 帖子](https://linux.do/t/topic/2064369) 的观点：** 认为“八股文”是对工程问题的共性高度抽象。它解决了 AI 上下文有限、验证慢的问题。背八股文本质上是人类在大脑中建立一套“标准答案库”，这样在写代码时能迅速给出模板，让 AI 在约束下生成一致性的代码。
* **[Twitter (X) 推文](https://x.com/AYi_AInotes/status/2048071414054318378) 的观点：** 介绍 Matt Pocock 通过一份 37 行的“官方术语表”来强制 AI 使用特定词汇。这不仅仅是改名字，而是通过限制词汇（禁止使用通用模糊词，改用精确术语）来“锁死” AI 的语言框架，强迫 AI 按照预设的逻辑去思考架构。

### 2. 它们共同解决的“痛点”

两份内容都指向了 **AI 辅助开发的共同困境**：
* **消除“正确的废话”：** AI 经常会说“我们要解耦、要模块化”，但这种通用描述没有执行力。通过八股文或术语表，人类给了 AI 一个具体的“锚点”。
* **降低沟通/上下文熵值：** 无论是八股文里的设计模式，还是术语表里的 Seam/Deep Module，都是一种**高压缩比的指令**。一个词就能代替几百行的描述，确保了输出的一致性。

### 3. 细微的视角差异

| 维度 | [LINUX DO 帖子](https://linux.do/t/topic/2064369) (八股文) | [Matt Pocock 术语表](https://x.com/AYi_AInotes/status/2048071414054318378) (语言约束) |
| :--- | :--- | :--- |
| **侧重点** | 侧重于**知识的存量**。强调人类要掌握标准化解法，才能指导 AI。 | 侧重于**规则的增量**。强调通过精简的 Prompt 基础设施来升级 AI 的表现。 |
| **应用场景** | 更偏向于“面试”和“快速交付”的工业流水线。 | 更偏向于“架构改进”和“代码重构”的精准工程。 |

---

### 综合判断

**是的，它们本质上是“版本答案”的两面。**

如果说 Vibe Coding（凭感觉编程）是**目标**，那么这两者提供的都是**路径**：
* **八股文**是“由内而外”的约束——人类理解了标准模式，所以能给 AI 下达标准指令。
* **术语表**是“由外而内”的约束——人类给 AI 划定了语言边界，迫使 AI 产生标准逻辑。

**结论：** 随着 AI 越来越强，编程的本质正在从“编写指令”变成“定义共识”。这两个 Tab 都在传达一个信号：**谁能定义更精准的语言和规范（不管是叫八股文还是术语表），谁就能真正驾驭 AI。**

你是因为在尝试用 AI 写架构，所以感觉到了这种“标准化”的必要性吗？


```






### 持续学习

现在AI相关范式创新太多了，是以周、以天作为维度更新、进化的

持续打磨自己的工具









## 怎么真正用LLM编程工具来提升自己的编程水平？



```yaml
#### 排查和追根溯源的能力
#
#也就是锁的 close 事情
#
#```markdown
#应用刚启动连接到数据库的时候比较慢，但又不是慢查询。
#
#1. 这位同学的解决办法是通过 tcpdump 来分析网络包，看网络包的时间戳和网络包的内容，然后找到了具体卡在了哪里。
#2. 如果是专业的 DBA 可能会通过 showprocesslist 看具体连接在做什么，比如看到这些连接状态是 authentication
#   状态，然后再通过 Google 或者对这个状态的理解知道创建连接的时候 MySQL 需要反查 1P、域名这里比较耗时，通过配置参数 skip-name-resolve 跳过去就好了。
#3. 如果是 MySQL 的老司机，一上来就知道连接慢的话跟 skip-name-resolve 关系最大。在我眼里这三种方式都解决了问题，最后一种最快但是纯靠积累和经验，换个问题也许就不灵了；第一种方式是最牛逼和通用的，只需要最少的知识就把问题解决了。
#
#我当时跟着他人 sudo、ls 等 Linux 命令开始
#```

```

### 用 LLM 提高效率，与用 LLM 提高能力，是两回事


LLM毫无疑问是很强大的工具，但是强大的工具，需要驾驭工具的人更加强大，才能真正用好。这是个很粗浅、不言自明的道理，不用多说。

其实 “用LLM提高效率”和“用LLM提高个人能力” 看起来是一码事，仔细一想是两码事，真正思考之后其实还是一码事。二者之间的差距在哪？在于复盘，更高效的复盘。

如果把我们每天工作替换为看书的话，按照 PQ4R 来说，我们可以理解为，在没有LLM时，我们每天只能读1-2本书，在有了LLM之后，我们的效率提高了3倍，每天都能读5本书左右。但是真正的问题在于，是否有这个 reflect, recite, review 的过程？


> “知道什么是好的，很重要，或者说，是最重要的 => 规范-sense”






### ***切换学习方向***


AI的抽象能力不足，从ChatGPT说话总是啰里八嗦、信息量不高就可见一斑

而人类的优势则在于 不够精确、抽象能力

因果链，抽丝剥茧的能力，

我们总说人类的问题在于“带宽不高，CPU也差，内存也差”


程序员的工作不是编程，而是通过抽象，来管理软件的复杂性。如果你做到了这一点，那么编程就很容易了。

-- 《你的工作不是编程》



https://tonybai.com/2026/04/04/the-death-of-coding-joy-in-the-age-of-ai-agents/


coder这份工作，真的很像纺织工人，在纺织工业化之前，你要学习，但在之后，









### 怎么真正借 AI 提升编程水平


```markdown
  ## 7. 用 LLM 提高效率，与用 LLM 提高能力，是两回事

  这个建议作为后半篇转折。
  可写：

  - 提高效率：让 AI 替你做执行层工作
  - 提高能力：让 AI 暴露你的思维漏洞
  - 如果只是让 AI 代写，你会越来越依赖
  - 如果让 AI 参与审题、拆解、对拍、复盘，你会成长更快

  ## 8. 怎么真正借 AI 提升编程水平

  你已有这个 heading，但内容还空。
  建议重点写：

  - 让 AI 解释设计权衡，而不是只要答案
  - 让 AI 提供多个方案并比较 trade-off
  - 让 AI 给你写测试，再反向理解接口设计
  - 让 AI review 你的设计，而不是代替你设计
  - 做完之后让 AI 帮你复盘：哪里是需求问题，哪里是实现问题，哪里是验证问题

  ## 9. AI 编程时代，程序员最该强化的能力

  适合做总结节。
  可写：

  - 抽象能力
  - 任务拆解能力
  - 上下文组织能力
  - 验证与调试能力
  - 工程判断力
  - 对系统边界和风险的敏感度
```






### “别让 AI 替你写作”


```markdown
写作的目的不在于写完，而在于增进你自己的理解，进而增进周围人的理解。

让 AI 为你写作，就像花钱请人为你健身一样。

-- 《别让 AI 替你写作》


https://x.com/lijigang/status/2041515855360754025

```





### 手写代码能力退化



```markdown
我们常说熟能生巧，我是一个有将近10年开发经验的后端工程师，但是我发现在最近这一两年更多使用AI编程之后，我对于语法的熟悉和掌握能力非常差，或者说几乎都忘光了，我还有着对于代码的 taste和sense，让AI辅助我能写出很好的代码，但是让我手写代码，则变得很难。
 
1、怎么看待这种情况？
 
2、手写代码能力是否仍然重要？
 
3、如果重要，那么怎么保持手写代码能力？如果不重要，应该怎么调整自己的编程能力（我的意思是，对于编程能力的评价体系是否需要有一个调整）？
```



```markdown
**1. 怎么看待这种情况？**

这是一种非常常见、正常且几乎是“必然”的现象，不用太焦虑——你不是一个人在“退化”，而是整个行业都在经历一次集体技能转移。过去10年，你靠手写代码积累了深厚的“肌肉记忆”和直觉（taste & sense），这是你的核心竞争力；现在AI把语法、样板代码、API调用这些“低级重复劳动”接管了，你自然会觉得“手写变难了”。这就像我们用计算器后心算能力下降、用导航后记路能力变弱一样，是“认知卸载”（cognitive offloading）的典型表现。

从各种研究和开发者反馈来看：
- AI确实会让开发者在**语法记忆、调试细节和概念掌握**上得分降低（Anthropic的一项研究显示，用AI辅助的组在刚用过的概念测试中比纯手写组低17%，调试能力差距尤其明显）。
- 但同时，你的“taste & sense”这种高阶能力反而被放大——AI帮你快速生成选项，你负责判断“好坏”、做架构决策、把控整体质量，这正是AI时代程序员价值提升的方向。很多大厂开发者（包括Karpathy本人）都公开承认“手写能力退化了”，但他们同时表示生产力大幅提高，更多精力放在系统设计和业务创新上。

本质上，这不是“能力下降”，而是**能力重构**：从“执行者”（手敲每行代码）转向“架构师 + 审阅者 + AI指挥官”。你还有10年经验打底，手感只是暂时生疏，并没有真正消失。

**2. 手写代码能力是否仍然重要？**

**重要，但重要性在下降，且不再是核心指标，而是“基础保障”和“护城河”。**

**仍然重要的理由（为什么不能完全放弃）：**
- **深度理解和调试**：AI生成的代码你得能看懂、改动、debug。没手写过类似逻辑的人，很难快速发现AI的“看起来对但逻辑错”的问题（hallucination）。
- **审查与质量把关**：团队里用AI的人越多，越需要有“老手”能一眼看出哪里可以优化、哪里有安全隐患、哪里违背了taste。你现在的“sense”就是这个优势。
- **极端场景**：面试（部分公司还在考LeetCode）、受限环境（内网、敏感项目）、AI罢工/不可用时。
- **长期认知健康**：像肌肉一样，不练就会萎缩。完全依赖AI，时间长了可能在复杂问题上“不会思考”。

**重要性下降的理由（为什么不用过度焦虑）：**
- 日常工作中，**语法和样板代码已经不是生产力的瓶颈**。Redis之父antirez都说过：“在绝大多数情况下，写代码本身已经不再是必要的工作。”AI时代，价值从“能手写”转向“能定义问题、设计系统、验证AI输出”。
- 很多顶级开发者（包括Vercel CTO）反馈：现在手写反而觉得“烦躁”，AI才是主流生产方式。

总结：**手写能力像“开车不看导航”的能力**——日常用导航更快，但关键时刻、复杂路况时，还是得自己会开。

**3. 如果重要，怎么保持？如果不重要，怎么调整编程能力的评价体系？**

**我的建议是“两者结合”：保留手写作为“底盘”，把AI协作能力升级为“新核心”。**

### 如何保持手写代码能力（简单可执行的做法）
- **每周固定“无AI日/无AI时段”**：比如每周有一天，或每天固定1-2小时，关掉Copilot/Cursor，纯手写一个小功能或重构一段核心逻辑。刚开始会很慢、很痛苦，但这就是“重建肌肉记忆”的过程。
- **刻意练习 + 对比复盘**：挑LeetCode中等/困难题，先自己手写（不用AI），再让AI生成一个版本，对比差异，问自己：“AI哪里比我好？我哪里可以学？”或者“这个AI方案的隐患是什么？”
- **把AI当老师而不是代笔**：遇到问题先自己想15-30分钟（写伪代码、画架构图），再问AI；或者让AI解释代码，但你自己手动改写关键部分。
- **额外强化**：参与开源项目（手动PR）、给新人code review、写技术博客/内部分享。这些都会逼你把“模糊的sense”变成可表达的知识。

### 如何调整编程能力的评价体系（新标准）
是的，**评价体系必须调整**，否则会用老眼光把自己“判死刑”。新能力评价可以参考以下维度（你可以拿来做个人OKR）：
- **AI指挥与验证能力**（新核心）：prompt质量、快速迭代AI输出、识别AI hallucination、优化AI生成的代码。
- **系统思维与架构设计**：能不能设计出可扩展、可维护的系统，而不是只管单文件代码。
- **问题定义与业务理解**：AI擅长“怎么做”，你擅长“做什么”和“为什么这么做”。
- **代码taste & sense**（你的优势）：评审质量、性能/安全/可读性把关。
- **学习速度与工具掌握**：新框架/语言用AI快速上手的能力。

未来程序员的竞争力公式大概是：
**老手写能力（底盘） + AI协作能力（加速器） + 架构/业务判断力（天花板）**

你已经有10年经验 + 良好的taste，现在只要**定期手动练一练 + 全力拥抱AI**，反而会比纯手写的老程序员更有优势。很多人焦虑的“被AI取代”，其实是被“不会用AI + 不会审AI”的人取代。

你现在的情况不是问题，而是**AI时代程序员的正常进化阶段**。继续保持好奇心和“sense”，你会比以前更强。需要具体练习方法或工具推荐，随时说！
```




### 去真正review代码





### 用sigma skills进行学习

https://github.com/HKUDS/DeepTutor


跟 sigma 做个对比



TS为例

```markdown
上面的感觉太空了，比如说就以
 

# FIXME: [sudheerj/ECMAScript-features: ECMAScript features cheatsheet](https://github.com/sudheerj/ECMAScript-features)

# FIXME: [TypeScript 入门教程](https://ts.xcatliu.com/)

# FIXME: [pipiliang/clean-code-typescript: TypeScript 代码整洁之道](https://github.com/pipiliang/clean-code-typescript)

 
 
TS语法为例，你觉得在AI时代，应该做出哪些调整？或者说，以此为例，对上面的几个问题分别作出解答
 
另外，上面的问题肯定不够充分，是否还有哪些我 unknown unknown 的相关问题？也都一并给我做出简答
```




```markdown
**1. 怎么看待这种情况？（以 TS 语法为例，变得超级具体）**

完全正常，而且**在 TS 上其实是“双刃剑”**：AI 把你从“记语法”解放出来，但同时让你对**类型系统**的肌肉记忆变弱。你贴的那些 FIXME 链接（ECMAScript features、TS 入门教程、clean-code-typescript）恰恰暴露了核心问题：

- **你现在很可能记不住**：
  - Mapped types 的精确写法：`type ToReadonly<T> = { readonly [K in keyof T]: T[K] }`
  - Conditional types + infer：`type ReturnType<T extends (...args: any[]) => any> = T extends (...args: any[]) => infer R ? R : never;`
  - Utility types 的组合用法：`Omit<Pick<T, K>, 'prop'>` 或者 `Partial<Record<string, string>>`
  - TS 5.x+ 的新语法（`satisfies`、`using` 声明、装饰器 metadata 等）

  以前你手敲 100 次才有 muscle memory，现在 AI 直接 `Ctrl+K` 一句 prompt 就生成，你自然“忘光了”。搜索结果显示，这不是个例——很多 5-10 年经验的 TS 开发者都反馈“用 Cursor/Claude 半年后，纯手写一个复杂 interface 都会卡壳”。

- **但你的 taste & sense 反而更值钱了**：
  AI 生成的 TS 代码经常出现“看起来类型安全但其实 runtime 炸”的问题（比如过度用 `any`、泛型推导过深导致编译卡死、类型收窄不彻底）。你 10 年经验能一眼看出“这个类型设计违反了 clean-code-typescript 第 12 条（避免魔法字符串）”或者“这个 mapped type 可以用 `keyof` + template literal 简化”。
  **本质**：AI 把“语法执行层”外包了，你从“码农”升级成“类型架构师 + AI 审阅官”。而且 TS 本身在 AI 时代反而**更吃香**——因为类型信息给 AI 提供了极强的上下文，AI 生成 TS 代码的准确率远高于纯 JS。

**结论**：不是你能力退化，是能力**从“记忆型”转向“判断型”**。那些 FIXME 链接现在的作用从“查语法”变成了“查 taste”——你用 AI 生成后，再对照这些资源做 code review。

**2. 手写代码能力（尤其是 TS 语法 + 类型）是否仍然重要？**

**重要，但只占 20-30% 权重，且重要性在快速下降。**

**仍然重要的 TS 具体场景**：
- **复杂类型调试**：AI 常把 deep generic（比如递归 mapped type 或 conditional infer 链）写崩，导致 `tsc` 报一堆“Type instantiation is excessively deep”。你得能手写简化版或手动加 `never` / `unknown` 收窄。
- **面试 / 受限环境**：很多公司还在考“不用 AI，手写一个带泛型的 Repository Pattern”。
- **Code Review 把关**：团队里 AI 生成的 TS 代码越来越多，你要能指出“这里用 `satisfies` 比 `as const` 更好”“这个 utility type 可以用 TS 内置的 `NoInfer` 避免”。
- **AI 罢工时**：内网项目、敏感系统、或 AI 突然限额/宕机，你得能快速手写一个 `type SafeParse<T>`。

**不那么重要的部分**：日常 CRUD、API 类型定义、简单 utility functions——这些让 AI 干，速度提升 3-5 倍。

**3. 具体怎么保持手写 TS 能力？怎么调整编程能力评价体系？**

**保持手写能力的“TS 版 3 步可执行计划”（每周 3-4 小时就够）**：

1. **每周“无 AI 重构日”**（固定周三晚上 1 小时）
   - 拿你项目里一段 AI 生成的 TS 代码（比如一个带泛型的 Hook 或 Service）。
   - **完全关掉 Copilot/Cursor**，自己手写重构，要求：
     - 必须用上 clean-code-typescript 里的原则（单一职责、类型收窄、避免 `any`）。
     - 必须手敲一遍那些你已经忘记的语法（mapped types、template literal types）。
   - 写完后再打开 AI，让它给你“diff”，对比哪里你比 AI 保守、哪里 AI 更优雅。
   - 目标：重建“手敲 10 次 = 记住”的肌肉记忆。

2. **针对你 FIXME 列表的刻意练习**（每周挑 1 个）
   - **ECMAScript features**：手写 3 个新语法糖的 TS 实现（比如 `Object.groupBy` 的类型定义）。
   - **TS 入门教程**：每天手动实现一个 utility type（从 `Partial` 到 `DeepPartial`），不准复制粘贴。
   - **clean-code-typescript**：挑 1 条规则（比如“Prefer readonly”），在项目里找 5 处违反的地方，手动改成符合规则的版本。

3. **AI 当“老师”而非“代笔”**
   - Prompt 改成：“先不要给我代码，先解释这个 mapped type 的 3 种常见写法，让我自己手写一个例子。”
   - 或者：“生成代码后，列出 3 个可能违反 clean-code-typescript 的地方，我自己改。”

**新的编程能力评价体系（建议你个人 OKR 直接用这个）**：

```yaml
- "老评价维度": "语法熟练度"
  "新评价维度（AI+TS 时代）": "**AI 指挥 + 类型审查能力**"
  "权重": "40%"
  "怎么自测（TS 具体例子）": "1 小时内让 AI 写出带复杂泛型的模块，你 review 出 3 个可优化点"

- "老评价维度": "手写速度"
  "新评价维度（AI+TS 时代）": "**架构设计 + taste 把关**"
  "权重": "30%"
  "怎么自测（TS 具体例子）": "设计一个满足 clean-code-typescript 的类型系统架构"

- "老评价维度": "Debug 细节"
  "新评价维度（AI+TS 时代）": "**Prompt 工程 + 验证速度**"
  "权重": "20%"
  "怎么自测（TS 具体例子）": "写出能让 AI 一次通过的 TS prompt（含上下文、类型约束）"

- "老评价维度": "记忆量"
  "新评价维度（AI+TS 时代）": "**学习新 TS 特性速度**"
  "权重": "10%"
  "怎么自测（TS 具体例子）": "TS 6.0 新功能上线后，24 小时内用 AI+手写落地一个 demo"
```

**总结公式**：
**老手写能力（底盘，20%） + AI 协作（加速器，40%） + TS 类型 taste + 架构判断（天花板，40%）**

**Unknown Unknowns（你可能没想到的相关问题）+ 简答**：

- **AI 在 TS 高级类型上其实很弱**：深层 conditional types、分布式条件类型、infer 链过长时，AI 经常 hallucinate 或导致编译爆炸。你需要学会“类型简化技巧”（手动拆解成中间类型）。
- **代码安全隐患放大**：AI 生成的 TS 可能类型安全但 runtime 有 XSS/SQLi（因为它只看类型不看业务上下文）。**调整**：每次 AI 输出后必须手动跑一次 type-check + 安全扫描。
- **团队协作新痛点**：大家全用 AI 后，PR 里“谁写的”变得模糊，code review 负担暴增。**解法**：建立团队 `CLAUDE.md` 或 `AI-REVIEW-CHECKLIST`（明确“禁止 any”“必须有 JSDoc”）。
- **新 TS 特性跟进变慢**：TS 每年大版本，你可能只靠 AI 知道“有这个功能”，但不知道“什么时候该用”。**解法**：每季度花 2 小时手写官方 release notes 里的新语法 demo。
- **极端场景生存**：公司突然禁用外部 AI（合规、内网）。**解法**：保持每月 1 次“纯 TS LeetCode 中等题手写练习”。
- **知识产权/合规风险**：AI 抄的 TS 代码可能带开源 license 问题，或在企业内被视为“非原创”。**解法**：重要模块必须自己重写核心逻辑。
- **长期认知健康**：完全不手写，可能会在“系统性思考”上变弱（无法从头设计一个大型 TS monorepo）。**解法**：每 3 个月做一个“从零手写小项目”（不用 AI）。

这些都不是危言耸听，而是 2025-2026 年真实开发者反馈的总结。

你现在的状态其实是**最优进化路径**：10 年经验 + taste 还在 + 已经拥抱 AI。只要按上面 TS 具体计划练 1-2 个月，手感就会回来，同时生产力还会再上一个台阶。需要我给你一个“每周 TS 无 AI 练习模板”或具体 prompt 示例，随时说！
```







https://x.com/shao__meng/status/2038426296993399195


https://github.com/Dimillian/Skills/blob/main/review-swarm/SKILL.md


```markdown
review-swarm 是一个只读、Multi Agents 并行审查的工作流 Skill，用于在代码变更（git diff 或指定文件）中发现四类关键风险：行为回归、安全隐私、性能可靠性、契约与测试覆盖。
https://github.com/Dimillian/Skills/blob/main/review-swarm/SKILL.md


-- 五步工作流 --

Step 1：确定审查范围与意图
· 优先级：用户明确指定的文件 > 当前 git 变更 > 分支/PR diff > 最近修改的文件
· 必须读取本地指引（如 AGENTS.md）和项目文档
· 构建「意图包」：明确应该改变什么、不应该改变什么、约束条件（兼容性、安全、迁移等）

Step 2：启动四个只读审查 Agent（并行）
· 意图与回归审查：变更是否符合预期意图，是否有意外的行为漂移、边界情况破坏、调用契约变更
· 安全与隐私审查：认证授权缺失、不安全输入处理、敏感数据泄露、风险默认配置
· 性能与可靠性审查：重复计算、热路径新增开销、资源泄漏、竞态条件、失败处理缺陷
· 契约与覆盖审查：API/类型/配置不匹配、向后兼容性问题、测试覆盖不足、缺失日志/指标

Step 3：聚合与过滤
主 Agent 负责合成，而非简单罗列：
· 去重、剔除弱证据/推测性结论、剔除与意图冲突的问题
· 过滤掉纯风格/可读性意见（除非隐藏真实 bug）
· 标准化输出格式：文件位置、分类、严重程度、影响说明、修复建议、置信度

Step 4：排序输出
· 高严重 + 高置信度
· 中等严重（建议合并前修复）
· 低严重或可延后处理

Step 5：给出清晰的前进路径
· fix now：合并前必须修复
· fix soon：有时间应改进
· optional follow-up：可安全忽略

设计亮点
· 并行分工：四个专业视角同时审查，避免单点盲区
· 只读原则：审查与修复分离，确保客观性
· 意图驱动：以「变更意图」为锚点过滤噪音
· 行动导向：输出的是「优先级修复清单」而非「问题清单」

适用场景
· 重大功能变更前的回归风险评估
· 安全敏感代码的 diff 审查
· 性能关键路径的变更验证
· 缺乏充分测试覆盖时的补充审查
```





---




### AI知识库


:::tip
Karpathy

https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f

garrytan

https://gist.github.com/garrytan/49c88e83cf8d7ae95e087426368809cb

:::



[2026-04-08]

我是感觉 Karpathy 的这套东西可能是硬伤大于实用性：

我们从输入到输出来分析整个流程，需要

实际上就一定需要 `Obsidian+Web Clipper` 把这些 webpage 放到 `raw`里，否则我们需要手动去存到本地

整个流程：raw喂资料 → LLM编译wiki → Obsidian问答+输出 → LLM自动维护 → 知识库自己滚雪球！

其问题不仅在于“会污染知识库”，更是在于 知识本身的更新 是很复杂的事情，context本身很可能反而导致输出质量（相对没有context）变差

“还有一个比较好的点是，它会让大模型对 Wiki 做健康度检查。比如：找一些自相矛盾的地方、补发一些缺失的信息、发现一些新的关联、提高一致性。”

https://github.com/SherwinQ/karpathy-wiki


我觉得首先要回归到，为啥我之前的这套方案已经是（当时的）最优解了。还是要回到当时的场景分析，才知道接下来应该怎么做。





```markdown
https://x.com/xicilion/status/2042091207787159683
---

ak 的个人知识库把大伙都带偏了。wiki 对 ai 并不友好，人也不会再有时间和耐心去看 wiki。
面向 ai 的知识库就是问题驱动的。既然都让 ai 清洗数据了，更好的方法是抽取知识图谱和问答库。
人要做的就是随时拍脑袋让 ai 随时拼出一篇 wiki。
```





Karpathy 这套workflow，对我来说的pros?

核心在于可以自动保留context，之后再研究该topic时，可以直接resume到之前的进度，接着研究。而非每次都要再去回忆context，再去想questions，更高效（因为实际上大部分情况下，靠自己去回忆都会丢进度）

对我来说，作为前置层存在。我的



需要一个从 data 发散出去，比如说发散到 blog 的中间层。我现在就直接把这个中间层放到 data 的YAML里了，要不就放到 blog的md里 （当然这是两类，在我认为还需要继续积累素材时，就放到YAML里。在认为素材已经足够了，准备写blog了，就放到md里进行积累）


```markdown
更准确一点，不是“再造一个主库”，而是新增一个 wiki folder 作为中间工作层，放在：

- raw/data 的上游下游之间
- data 和 blog 之间
- 人工素材积累和正式发布之间

你现在的问题本质上是少了一个“可反复编译、可被 agent 操作、但又不直接污染正式资
产”的层。这个 wiki 正好补这个空位。

所以你的理解基本是对的：

- 还在收集、对比、发散、没收敛的内容，不适合直接进正式 data
- 已经准备成文、面向表达的内容，直接进 blog 又太早
- wiki 就是这两者之间的夹层

我会把它定义成：

- data：正式结构化知识资产
- wiki：研究/编译/综合/演化层
- blog：面向外部表达的发布层

```


5    6s   20h ago tg git:fetch -- https://github.com/Ss1024sS/LLM-wiki
4    6s   20h ago tg git:fetch -- https://github.com/Paul-Kyle/palinode
3    8s   20h ago tg git:fetch -- https://github.com/duct-tape-and-markdown/fre
2    6s   20h ago tg git:fetch -- https://github.com/Ar9av/obsidian-wiki
1    2m    2h ago tg codex










### “只保留短期和长期TODO，永远不做中期规划”

这点也是最近感悟到的一点，在很久之前我会，后来又结合“科维四象限”改成了 FIXME, TODO, PLAN, MAYBE，分别对应 重要且紧急、中期、长期规划。正好在我


> 中期TODO短期化



https://x.com/chenchengpro/status/2040808769899356527





OpenAI 内部的规划哲学是只做近期（8 周以内）或远期（方向感），永远不做中期产品路线图

近期是 8 周以内，最多 8 周，而且要是一个具体的目标，团队能够围绕它集中发力。OpenAI 擅长的就是这种短周期的团队冲刺。
远期是一种“感觉”。比如：一年以后我们会有更聪明的模型，用户不会想把自己的电脑借给模型用（因为那样一次只能做一件事），会有无限多个模型同时独立工作、自己验证结果、甚至自己部署和监控代码，用户可能根本不需要主动输入提示词。
中间那段呢？产品路线图？基本不存在。他们有的是长期方向加上他们认为能朝那个方向推进的具体项目。


这种规划方法的前提是模型能力在快速变化。当你不确定三个月后模型能做什么，中期路线图就变成了猜测。但这个前提本身就值得追问：如果模型进展放缓了呢？







## Ref


***[A.I. Should Elevate Your Thinking, Not Replace It - Blog - Koshy John](https://www.koshyjohn.com/blog/ai-should-elevate-your-thinking-not-replace-it/)*** “思想外包”




## 总结





[讲真，Ai编程对人的要求更高了 - 搞七捻三 - LINUX DO](https://linux.do/t/topic/1844995)


判断力

多线程执行能力

清晰的目标和交付，完整的闭环。也就是框架要强，不要被model牵着走。









https://tonybai.com/2026/03/29/stop-mindless-ai-coding-we-are-heading-to-a-dead-end/








https://www.bilibili.com/video/BV15N9FBtEyc/?spm_id_from=333.1007.top_right_bar_window_dynamic.content.click&vd_source=f93a90ecd1f4fbda93651d654ff4c882


https://linux.do/t/topic/1888899



https://x.com/chenchengpro/status/2039707154371018930






---


https://github.com/ChrisWiles/claude-code-showcase



```markdown
**是的，这个 repo（ChrisWiles/claude-code-showcase）完全可以理解为「AI 编程工具（尤其是 Claude Code）使用的最佳实践说明」。**

它不是一个普通的工具，而是**一个完整、可直接拷贝的“Claude Code 项目配置模板”**，专门展示如何把 Claude Code 从“单纯的代码生成器”升级成“超级智能工程搭档”。作者把自己在真实项目里验证过的所有高级配置打包成一个 showcase，让其他人直接照着搭，就能实现自动化质量把关、领域知识复用、代理式工作流、定时维护等“低垂果实”。

repo 当前（2026.4）有 **5.7k stars**，MIT 协议，明确写着 “Use this as a template for your own projects.”，定位就是**最佳实践示范仓库**。

下面我**严格按照它的 README**，给你逐层拆解它到底在教什么、怎么体现“最佳实践”：

### 1. 核心理念（README 开头就点明）
> “Most software engineers are seriously sleeping on how good LLM agents are right now... The real unlock is building a solid set of reusable 'skills' plus a few 'agents' for the stuff you do all the time.”

它把 Claude Code 的**最佳实践**总结为两点：
- **Skills（技能）**：把项目里的“领域知识、编码规范、架构模式”写成文档，让 Claude 每次生成代码时自动遵守（不再重复教）。
- **Agents（代理）**：让 Claude 自己扮演特定角色（代码审查员、票据处理员等），实现主动式工作。

### 2. 推荐的项目目录结构（最佳实践模板）
README 直接给出了标准目录（直接 copy 进你的项目就行）：

```
your-project/
├── CLAUDE.md                      # 项目记忆卡（最重要！）
├── .mcp.json                      # 外部工具集成（JIRA、Linear、GitHub 等）
├── .claude/
│   ├── settings.json              # 钩子 + 权限配置
│   ├── settings.md                # 人类可读的钩子文档
│   ├── agents/                    # 自定义代理（如 code-reviewer.md）
│   ├── commands/                  # 斜杠命令（如 /ticket、/onboard）
│   ├── hooks/                     # 自动化脚本（技能自动匹配、pre-tool-use 等）
│   ├── skills/                    # 领域知识包（每个文件夹一个 SKILL.md）
│   └── rules/                     # 模块化指令（code-style.md、security.md）
└── .github/workflows/             # GitHub Actions 自动化
```

这是它认为的**最优项目组织方式**，让 Claude Code 能“记住”整个项目上下文。

### 3. 具体最佳实践模块（README 逐一讲解如何实现）
- **CLAUDE.md（项目记忆）**
  把技术栈、关键目录、代码风格、测试命令等一次性写清楚。Claude 每次会话都会自动读取，避免重复说明。

- **Skills（技能包）**
  示例：`core-components/SKILL.md`、`testing-patterns/SKILL.md`、`graphql-schema/SKILL.md`
  → Claude 生成 UI、测试、GraphQL 时自动套用你的规范。

- **Hooks（钩子）**
  最强自动化：
  - 改代码前自动格式化 + 跑测试
  - 主分支禁止直接编辑
  - 提示词提交时自动匹配最合适的 Skill（skill-eval 引擎）

- **Agents（代理）**
  示例：`code-reviewer.md` —— 每次改动后自动按清单审查（TypeScript strict、错误处理、loading states 等）。

- **Commands（斜杠命令）**
  `/ticket`：一键读取 JIRA/Linear 票据 → 实现功能 → 更新 ticket 状态 → 关联 PR。

- **GitHub Actions 工作流**
  - PR 自动 Claude Code 审查
  - 每周代码质量巡检 + 自动修复
  - 每月文档同步
  - 双周依赖审计 + 安全更新

- **MCP Servers 集成**
  让 Claude 直接操作外部系统（票据、CI 等），实现闭环。

### 4. README 里的“Best Practices”部分（核心精华）
虽然 README 内容较长，但它专门有一节 **Best Practices**，强调：
- 把重复性知识写成 Skills/Agents，而不是每次 prompt 都教。
- 用 Hooks 做“质量门禁”，把人工 review 降到最低。
- 结合 GitHub Actions 实现“无人值守维护”。
- 通过 MCP 把 Claude 变成真正的“全栈工程代理”。

### 总结：为什么这就是“AI 编程工具的最佳实践说明”？
这个 repo 把 2026 年 Claude Code（以及类似 Cursor / Windsurf / Claude Code CLI）的**进阶用法**系统化、可复制化了。它告诉你：
- 别只用 Claude 写代码 → 要让它“懂你的项目、守你的规则、主动干活”。
- 真正的生产力飞跃来自**配置**（Skills + Agents + Hooks + 集成），而不是 prompt 技巧。

如果你正在用 Claude Code / Cursor 等 AI 编程工具，直接 fork 这个 repo，把 `.claude/` 文件夹和 `CLAUDE.md` 复制到自己项目里，就能立刻获得“作者级”最佳实践配置。

**想现在就上手吗？**
我可以直接给你：
- 最简版 CLAUDE.md 模板
- 推荐的 skills 写法
- settings.json 核心钩子配置

或者你告诉我你的项目类型（React / Node / 全栈 / 其他），我帮你定制一份。需要吗？
```



https://github.com/luongnv89/claude-howto






[【闪客】你管这破玩意叫 Harness？虚拟世界的牛马套餐！_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1cNdrB4Evw/)


```markdown
**《Harness 这个词为什么突然大火？完整总结》**

这个视频的核心观点是：**Harness（驾驭工程）并不是一个严格定义的新技术，而是一个被重新包装的古老概念**——如何更好地**控制和引导**一个强大但容易失控的智能体（AI），让它按照人类的预期高效、安全、稳定地完成任务。

### 视频用“老板 vs AI员工”角色扮演，梳理了AI对话范式的演进史：

1. **Prompt Engineering（提示词工程）**
   - 阶段：AI还是“实习生”，能力弱、经验不足。
   - 核心：通过优化说话方式、话术、技巧（think step by step、格式要求、PUA大法等）来激发模型潜力。
   - 总结：**调整和模型的“沟通方式”**。

2. **Context Engineering（上下文工程）**
   - 阶段：AI进化成“老油条”，模型能力变强。
   - 核心：不再是话术问题，而是**信息不足**。需要给模型补充关键上下文（手动写、RAG、工具调用、memory、skill 等）。
   - 总结：**给模型提供必要的信息和工具**。
   - 提示词工程被视为它的子集。

3. **Harness Engineering（驾驭工程 / Harness）**
   - 阶段：AI已经很强，信息也给够了，但**行为还是容易偏离预期**。
   - 核心问题：即使每一步都没错，最终结果也可能南辕北辙（视频里那个“买充电器结果丢手机还欠贷款”的经典故事）。
   - 需要做的事：**制定约束、权限收敛、规范、对齐、流程控制**等，让AI的行为被“套上缰绳”。
   - 总结：**对AI进行限制和引导**，确保它朝着我们想要的方向走，而不是只追求“完成任务”。

### 视频对“Harness”的更深层拆解（作者认为更合理的视角）：

作者认为把 Prompt / Context / Harness 强行并列其实边界模糊、不够优雅。他提出一个**两层驾驭**的框架：

- **第一层驾驭**：Agent 如何驾驭大模型（这部分常被混入 Harness 的讨论，包括 Cursor / Claude 的源码思路）。
- **第二层驾驭**：**人（或 Spec 框架）如何驾驭 Agent** —— 这才是目前大家最关心、也最实用的 Harness。

**Harness 的本质**：
- 不是某个具体技术，而是一系列**让强大智能可控**的办法总和。
- 核心思路（来自 Anthropic 等）：
  - 不盲目压缩超长上下文，而是**重启新 Agent + 传递状态**（通过说明文档、内存文件等方式交接）。
  - 使用 Spec / Plan / Spec Tree 等框架，把“提出需求 → 实现 → 归档”的流程规范化，记录在磁盘上，形成跨 Agent 的持续工作机制。
  - 类似公司管理：从“个人英雄主义” → “组织协作” → “制度与规范”。

### 视频的核心洞见（技术演进规律）：

- **功能会不断下沉**：今天需要手动 Harness 的东西，明天就会被内化到模型、Agent 或框架里（例如 Claude 的记忆功能就把部分跨 session 能力内化了）。
- **人类是懒惰的**：一切能写成 SOP（标准操作流程）的，最终都会变成工具/框架。
- **Harness 的终极目标**：让 AI 越来越“听话”、可预测、安全，最终实现“一句话赚 100 万”，剩下的都内化到底层。

### 作者个人观点总结：

- 当前流行的“Prompt + Context + Harness”三件套划分虽然好看，但边界模糊，不利于真正理解。
- 更准确的视角是**多层驾驭**：人驾驭 Agent，Agent 驾驭 LLM，随着能力提升，驾驭层级会不断简化或内化。
- Harness 其实就是我们**一直以来都在做的事**——只是 AI 变强了，需要更系统、更高级的“缰绳”。

**一句话总结整个视频**：

**Harness 不是什么高深的新发明，它就是“如何有效驾驭一个越来越聪明的 AI 员工”，让它不跑偏、不失控、稳定交付我们真正想要的结果。**
它火起来的原因很简单：AI 能力已经够强了，现在最大的瓶颈不再是“怎么让它聪明”，而是“怎么让它乖乖听话、按照我们的剧本走”。

你本来就活在被各种 Harness 过的世界里（公司制度、法律、流程、SOP……），只不过现在这个词被借来描述 AI 时代的控制问题罢了。

总结完毕。需要我再提炼成更短的一句话版、要点列表版，还是针对某个具体部分深入解释吗？
```



```markdown
这段内容的核心是在讲：**“harness / harness engineering（驾驭工程）为什么会火，以及它到底在说什么。”**

可以概括成 5 点：

**1. 这不是一个全新的东西，更像是老问题的新命名。**
作者认为，很多人把 harness 挂在嘴边，但它其实并没有一个严格统一的定义。它之所以流行，不是因为它突然发明了什么新技术，而是因为大家都在面对同一个问题：**怎么把强大但不稳定的 AI，约束到可控、稳定、持续产出的方向上。**

**2. AI 使用范式经历了三层演进：prompt → context → harness。**
作者把这段历史讲成一个“老板带员工”的故事：

* 一开始模型不太行，只能靠优化说话方式，所以流行 **Prompt Engineering**。
* 后来发现不是“不会说”，而是“信息不够”，于是变成补充上下文的 **Context Engineering**。
* 再后来，信息和工具都有了，问题变成“它会不会把事情做歪、做过头、失控”，于是出现了 **Harness Engineering**，也就是对 AI/Agent 加约束、定规范、收权限、做状态管理。

**3. 作者不认可把这三者切得太死。**
文中反复强调：这三者的边界其实很模糊。所谓 prompt、context、harness 的划分，更多是为了讲起来方便、形式上好看，不代表现实里真有那么清晰的分界。很多时候它们本来就是混在一起的。

**4. harness 的本质，是“驾驭”的层层转移。**
作者提出一个更重要的视角：

* 以前是**人直接驾驭大模型**；
* 现在越来越多时候，是 **agent 在驾驭大模型**；
* 然后又变成人去驾驭 agent；
* 再往后，可能是 spec/framework 去驾驭 agent，人再去驾驭 spec。

所以 harness 不是某一个固定技术点，而是一种更广义的事情：**谁来约束谁、谁来管理谁、谁来保证长期任务不跑偏。**

**5. 未来趋势是：通用能力不断下沉，人类越来越少手动操心。**
作者最后给出的判断是：

* 一切能沉淀成 SOP 的东西，最后都会被工具化、框架化；
* 一旦某种能力足够通用，就会“下沉”到底层，变成内置能力；
* 所以今天你还需要手动做的很多 harness 动作，未来可能会被模型、agent、IDE、spec 框架自动吸收。

最终目标就是：**人只提目标，剩下的控制、衔接、协作、约束，都逐层内化。**

**一句话总结：**
这篇内容想表达的是，**harness 并不是一个定义严密的新发明，而是对“如何让 AI/Agent 在复杂任务中稳定、可控、不失控地工作”这一整类方法的重新命名。** 它的火爆，反映的不是概念本身有多新，而是大家都越来越需要“驾驭智能体”这件事。

你要的话，我也可以把它再整理成一版更适合发视频简介的 **100 字精简版**。

```

```markdown
给你一版适合放视频简介的精简版：

**Harness 并不是一个定义严密的新概念，而是“如何把 AI/Agent 驾驭得更稳定、可控、不跑偏”的统称。它本质上是从提示词工程、上下文工程继续演进出来的控制层思路。之所以突然火，不是因为它多新，而是因为大家都开始真正面对“如何管理智能体”这个问题了。**

要更像视频口播风格的话，也可以写成：

**Harness 不是啥神秘黑科技，说白了就是：怎么把越来越强的 AI 和 Agent 管住、用顺、用稳。它火，不是因为定义多清晰，而是因为这已经成了所有人都绕不开的新问题。**

```




[(1) Vox on X: "I Compared gstack, Superpowers, and Compound Engineering. They Solve Three Completely Different Prob" / X](https://x.com/Voxyz_ai/status/2038237755654783107)



[(1) Jason Zuo on X: "一个从执行到记忆的完整 Agent Harness: gstack + Compound Engineering：" / X](https://x.com/xxxjzuo/status/2038086450013495554?s=46&t=ohg9SA3Qh-om3XLI2rHDlA)

```markdown
https://x.com/xxxjzuo/status/2038086450013495554?s=46&t=ohg9SA3Qh-om3XLI2rHDlA
 
 
按照他这个说法，用了CE，是否能同时替代掉 SuperPowers + harness?
 
或者说，你觉得在多大程度上能替代掉这两个？来做个客观评估

---


那如果用CE来维护 知识库你觉得可行吗？也就是个人笔记，是否有哪些相应的skill来解决该问题？
```
