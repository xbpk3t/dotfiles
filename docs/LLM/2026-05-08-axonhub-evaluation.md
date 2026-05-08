---
title: AxonHub
---



:::tip[TLDR]

本文用来review整个把 `LLM网关`从 MetAPI换到AxonHub 的整个过程

具体逻辑为以下三部分

- 1、为啥不想再用 MetAPI
- 2、换哪个？为啥最终选择 AxonHub？
- 3、AxonHub 具体用法


:::




## 为啥不想再用 MetAPI

MetAPI 在过去一段时间确实帮了不少忙——它把 New API、One API 这些中转站聚合起来，提供余额、签到、模型自动发现等能力。但到了后期，问题越来越明显：

- **更新极慢**，很多 issue 长期无人处理
- **Bug 不修**，一些直接影响使用的稳定性问题拖了很久
- **链路风险**：MetAPI 一旦出问题，所有 agent 都跟着断

这些问题的根源在于 MetAPI 的核心定位是"中转站的中转站"，而非稳定的 API 网关。当它作为主链路入口时，它的维护节奏就成了我的单点故障。

所以我决定换掉它。而且一旦换掉，**不会再用回去**——哪怕有些功能暂时缺失，也比把主链路压在一个不可控的中转站聚合器上要好。

### 切换到 AxonHub 后的功能缺失

承认事实：从 MetAPI 切到 AxonHub，确实会丢失一些能力。但每一条我都评估过，结论是**要么可解决，要么无所谓**。

| 缺失能力 | 说明 | 是否可克服 |
|---|---|---|
| 中转站资源池聚合 | MetAPI 可以把 New API / One API / Veloera 等站点聚合成一个资源池 | 我主力使用的是官方 API Key（OpenAI / Anthropic / DeepSeek），不需要中转站聚合 |
| 自动模型发现 | MetAPI 会自动发现上游站点的模型列表 | AxonHub 有 channel model 查询，手动配一次即可，模型不会天天变 |
| 余额查询 / 自动签到 | MetAPI 有余额看板和签到功能 | 用官方 API Key 不存在余额问题，也不靠签到额度 |
| 订阅转 API / 2api | MetAPI 支持把 ChatGPT Plus / Claude Pro 等网页订阅转成 API | 我使用的是官方 API Key，不需要走订阅转 API |
| Responses API partial support | AxonHub 对 OpenAI Responses API 标注了 partial support：支持 `POST /v1/responses` 的基础生成、流式输出，并在同一上游渠道场景下支持 `previous_response_id` passthrough；但尚未完整覆盖 OpenAI Responses API 的全部接口与协议语义 | 实测基础生成、streaming、tool calls 都正常。非 `passThroughBody` 模式下对 Codex/MCP tools 的最新字段和 SSE 事件存在兼容缺口——但开启 `passThroughBody` 后问题消失。对我当前使用场景够用 |
| 个人维护风险 | AxonHub 是个人项目，README 提示了维护风险 | 这也是我权衡过的。但与其赌一个**已经出现维护问题**的项目，不如赌一个**目前很活跃**的项目。而且 AxonHub 的架构和代码质量明显更好，即使停更，fork 自维护的成本也比 MetAPI 低 |

**结论：MetAPI 有它的舒适区，但那些舒适区我不再需要了。**






## 换哪个？为啥最终选择 AxonHub？


### 可选方案

***[关于个人使用的大模型路由项目 - 开发调优 - LINUX DO](https://linux.do/t/topic/1855261)***

- LiteLLM
- AxonHub
- octopus [bestruirui/octopus: One Hub All LLMs For You | 为个人打造的 LLM API 聚合服务](https://github.com/bestruirui/octopus)






### AxonHub vs LiteLLM

两个主流的 AI Gateway / Router 方案，定位有差异，直接对比：

| 对比项 | LiteLLM | AxonHub |
|---|---|---|
| 核心定位 | AI Gateway / Router / SDK | AI Gateway + 管理平台 |
| Provider 覆盖 | 100+ provider，生态更成熟 | 支持主流 provider |
| OpenAI-compatible API | ✅ | ✅ |
| Anthropic / Gemini 协议互转 | ✅ | ✅ 更强调，Any SDK → Any Model |
| Codex / Responses API | ✅ 支持更完整 | ⚠️ partial support |
| Provider rank / priority | ✅ `order` 参数 | ✅ Model Association Priority |
| Load balancing 策略 | 5 种策略，更丰富 | ✅ smart load balancing |
| 管理 UI | ✅ 有，偏运维控制台 | ✅ 更产品化，channel/trace/request monitor 直观 |
| Trace / debug | ✅ | ✅ 更强，核心卖点 |
| Request override | ✅ 工程化配置 | ✅ 产品化管理 |
| 部署复杂度 | 需要 Postgres 才能用全功能 | Docker 化，UI 体验完整 |
| 维护成熟度 | ✅ 更成熟，生态大 | ⚠️ 较新，个人维护 |

**一目了然的差异**：
- 选 **LiteLLM**：你更看重路由成熟度、Responses API 兼容、丰富的 routing strategy
- 选 **AxonHub**：你更看重 UI 体验、trace 可视化、协议互转、channel 管理





### 为啥最终选择了 AxonHub?

对比了一圈之后，最终选 AxonHub 的原因：

**1. 产品化体验更好**

LiteLLM 的核心是个 Proxy Server，UI 是附带的。AxonHub 从设计上就是个产品——channel 管理、model mapping、request trace、request monitor 都在 UI 里完成，日常使用和管理更直观。

**2. 协议互转是主打能力**

AxonHub 强调 "Use any SDK, access any model"——用 OpenAI SDK 调 Claude、用 Anthropic SDK 调 GPT，自动做 API format translation。如果 agent 生态里各种 SDK 混用，这个能力很实用。

**3. Resource rank 语义清晰**

AxonHub 的 Model Association Priority 和我的需求刚好对口——priority 0 走主通道，priority 10 走 backup，priority 50+ 走 emergency。同优先级还能用 weight 控制分流比例。这和 MetAPI 的资源池 rank 思路类似，只是不需要中转站账号层面的调度。

**4. 部署简单**

一个 Docker Compose 搞定，PostgreSQL 是唯一依赖。没有复杂的 routing strategy 配置，不需要理解 LiteLLM 的 YAML 语义。

**5. 为什么不叠三层架构（LiteLLM + AxonHub + MetAPI）**

ChatGPT 给出的推荐方案是多层叠加。但对我来说：

- **不需要 MetAPI**：我主力是官方 API Key，不需要中转站资源池。MetAPI 在这个架构里只做 fallback，而它的维护问题正是我离开的原因，继续留着意义不大
- **不需要 LiteLLM**：AxonHub 自身已经有 failover、priority、load balance，不需要在它前面再套一层 LiteLLM 做路由
- **减少链路复杂度**：单网关单数据库，出问题查起来更简单。多层链路每加一层就多一个排障点和故障点

**结论：对于"个人 + 官方 API Key + 单网关"的场景，AxonHub 单独使用是最直接的方案。**





## AxonHub 具体用法



### 是否支持类似 MetAPI 的资源池 rank，也就是优先用哪个 provider？

**支持，但语义略有不同。**

AxonHub 通过 **Model Association Priority** 实现优先级路由。一个模型可以关联多个 channel，每个 channel 设置 priority 值：

- **priority 数值越小，优先级越高**
- 例如：priority 0 是主通道，priority 10 是 backup，priority 50–100 是 emergency
- 同一 priority 组内，支持用 `weight` 控制流量比例

```text
模型: claude-sonnet
  priority 0  → Anthropic 官方 API（weight 100）
  priority 10 → OpenRouter Claude（weight 30）
  priority 20 → 其他 fallback 渠道
```

和 MetAPI 的区别在于：MetAPI 的 rank 是围绕中转站账号的余额、成本、使用率做的全局调度；AxonHub 的 priority 是 provider 级别的路由优先级。对我来说后者够用且更可控。


### 关于 AxonHub / LiteLLM 是否支持 Codex OAuth 作为 provider

先说结论：**从 v0.9.37（2026-04-24 发布）起，AxonHub 已支持直接导入 Codex `auth.json`。**

具体来说：

- **AxonHub 支持 Codex 客户端接入**：Codex 可以把 AxonHub 当成 OpenAI endpoint，配置 `base_url → http://127.0.0.1:8090/v1`、`wire_api → responses`，由 AxonHub 做模型路由
- **Codex OAuth 渠道 + auth.json 导入已完整支持**：AxonHub 有 Codex provider channel 和 OAuth 认证流程。`auth.json` 导入功能在 #1425 提出后，于 #1465 在 2026-04-23 合并，随 v0.9.37 发布。可以通过粘贴 raw JSON 或文件路径配置凭据
- **版本注意**：如果使用的是 v0.9.36 或更早版本，需要升级到 v0.9.37+ 才能使用 auth.json 导入

**LiteLLM 在这方面曾更早成熟**，它有 ChatGPT Subscription provider，支持 `CHATGPT_AUTH_FILE=auth.json` 的环境变量配置。但 AxonHub 现在也已经追平这个能力了。对我来说这不是选择障碍——我走的是官方 API Key 路线，不依赖 Codex OAuth / ChatGPT subscription 转 API。

### 数据库选型：SQLite vs PostgreSQL

AxonHub 支持 SQLite 和 PostgreSQL。我的选择：**个人高频使用，直接 PostgreSQL。**

SQLite 能跑，但不值得。原因很简单：AxonHub 不只是配置面板，它会持续写入 request trace、cost tracking、channel status、usage log。SQLite 的写并发限制（同一时间只有一个 writer）在高频 streaming 请求场景下，迟早会遇到 `database is locked` 或 trace 写入拖慢响应的问题。

AxonHub 官方文档的定位也很明确：SQLite = Development，PostgreSQL = Production。

| 场景 | 选择 |
|---|---|
| 本地试用 | SQLite |
| 个人低频 | SQLite 可以 |
| **个人高频（从早到晚）** | **PostgreSQL** |
| 主力 agent router | PostgreSQL |

PostgreSQL 对 AxonHub 来说只是多一个容器，但能避免后续遇到锁库、trace 写入异常、迁移折腾等问题。



## 需要澄清的几个问题 [2026-05-08]

以下三点在调研过程中容易混淆或理解偏差，单独展开说明。

### 协议互转：不是所有场景都无损

AxonHub 的主打能力确实是多协议网关——可以用 OpenAI SDK 调 Claude、用 Anthropic SDK 调 GPT，由网关做 API format translation。日常文本、普通 streaming、generic function tool calls 基本都覆盖了。

但它不是所有 provider-specific 能力的无损互转层。几个已知边界：

- **Provider-specific tools**：generic function tools 可以跨 provider 转换，但 OpenAI 的 web search、code interpreter、file search、computer use 等不支持跨协议转换；Anthropic 侧也一样
- **Reasoning / thinking**：这块仍在活跃演进中，release notes 里近期还在修 deepseek reasoning 内容聚合、Anthropic adaptive thinking 等问题，不是完全稳定的底层抽象
- **Image / 多模态**：image generation streaming 当前不支持；多模态输入在跨协议转换时也可能存在语义差异

如果你主要在文本生成 + streaming + generic tool calls 场景使用，协议互转体验很好；但如果重度依赖 provider-specific 能力（比如 Codex 的 computer use、web search），需要留意这个边界。

### 负载均衡：AxonHub 不只是 "smart"

对比表里写 LiteLLM 有 5 种策略，AxonHub 只写了 "smart load balancing"，容易让人觉得 AxonHub 的 LB 很模糊。实际上 AxonHub 有三类策略：

- **Adaptive**（默认）：综合 latency、error rate、current load、rate limit、RPM/TPM、权重、并发队列等信号打分选最优 channel
- **Failover**：偏权重 / 随机，失败时切换到下一候选
- **Circuit Breaker**：避开高失败率的 model/channel

此外还有 candidate selection 层，会按 model mapping、association rules、prompt_tokens、是否 streaming、channel profile 等过滤候选。所以它的 "smart" 不是 marketing 空话，而是实际的自适应调度。

**差距在哪儿**：LiteLLM 的策略更显式可配置——你可以明确选 simple-shuffle、least-busy、usage-based、latency-based、cost-based、custom routing。尤其是 cost-based routing（按最低成本选 channel）是 LiteLLM 的明确优势，AxonHub 有成本追踪但没有把 cost 公开为独立的路由算法。

所以差距不是 "AxonHub 没有负载均衡"，而是 LiteLLM 暴露了更细的用户可选策略，AxonHub 更像开箱即用的自适应调度 + 熔断故障转移。

### octopus 的定位：轻量个人 Hub，非 MetAPI 对位替代

[octopus](https://github.com/bestruirui/octopus) 进入候选名单的原因是有漂亮的 Web UI、多 channel / 多 key、OpenAI Chat / Responses / Anthropic 协议转换、以及 Round Robin / Random / Failover / Weighted 负载均衡。对轻量自用来说不错。

但最终没有深入对比它，原因是：

1. **它不是 MetAPI 的对位替代**。MetAPI 的核心是"中转站的中转站"——把 New API、One API、OneHub、DoneHub、Veloera、AnyRouter、Sub2API 等中转/聚合平台再聚合成统一网关，并围绕账号/余额/签到/自动续期/成本信号做路由。octopus 更像个人版 API Hub，不是专门做多中转站账号管理的 meta-aggregation layer
2. **协议转换层借鉴了 AxonHub**。它的 README 明确说明 API adaptation module 来源于 AxonHub，所以这不是它对 AxonHub 的差异化优势
3. **路由策略偏基础**。Round Robin / Random / Failover / Weighted 对个人场景够用，但不如 LiteLLM 和 AxonHub 丰富

结论：octopus 适合轻量个人 API Hub 场景，但作为 MetAPI 的主要替代方案，AxonHub 或 LiteLLM 更对位。


## helicone + litellm [2026-05-08]


:::tip[TLDR]

[Helicone/helicone](https://github.com/Helicone/helicone)

Helicone 是 LLM 可观测性平台，定位类似 "Sentry/Datadog for LLM"。它和 LiteLLM 互补不互替——LiteLLM 负责网关/路由，Helicone 负责观测/tracing/成本分析。这套组合是生产级方案，适合有线上用户的 AI 产品/agent 场景。个人使用一般偏重，AxonHub 的一体化体验更直接。

:::

### Helicone 是什么

Helicone 可以理解成给 LLM 应用加的"监控台 + 网关层"。它不是模型，也不是 agent 框架，而是夹在应用和 OpenAI / Anthropic / Gemini 等模型服务之间的一层，用来：

- 记录每次 LLM 请求的输入输出
- 追踪成本和 token 用量
- 分析延迟和错误
- 做 session tracing（把 agent / RAG / 多轮对话的多次调用组织成一条 trace）
- 做缓存、fallback、provider 路由
- 管理 prompt 版本和 eval 分数

和 LiteLLM / AxonHub 的核心差异在于：Helicone 更偏 **observability-first**。它也能做 AI gateway，但真正强的是把 LLM 调用变成可查询、可分析、可复盘的产品数据。

### Helicone + LiteLLM 的分工

一个常见的误解是"Helicone 就是 LiteLLM 的 WebUI"。不是。

```text
LiteLLM = 统一模型出口 / 网关 / 路由 / key / budget / fallback
Helicone = LLM 请求日志 / observability / cost / latency / session trace / prompt 分析
```

类比一下：

> **LiteLLM 是 Nginx / API Gateway。Helicone 是 Datadog / Sentry / 产品分析后台。**

LiteLLM 自己也有 Admin UI，可以管理模型、virtual keys、teams、users。Helicone 是另一层 observability，不只是 UI。LiteLLM 官方也有 Helicone 集成，可以通过 provider 或 callback 方式把日志送到 Helicone。所以它们可以组合用，但职责完全不同。

### 什么场景应该考虑这个组合

Helicone + LiteLLM 不是个人使用的默认推荐，而是面向这些场景的：

**核心判断**：如果你的 LLM 功能已经有真实用户在生产环境使用，并且你开始关心这些问题：

- 哪个用户最烧钱？哪个 feature 调用最多？
- 为什么这个请求慢？为什么它失败了？
- 某个 agent session 中间哪一步出错了？
- 这个 prompt 版本改了之后质量有没有变好？
- 每天总成本是多少？趋势如何？

只要命中其中几条，就值得考虑。

Helicone 的决策清单更具体——如果以下条件命中 **3 条以上可以试点，5 条以上建议上**：

1. 你的 LLM 功能已经在线上服务真实用户
2. 每月 LLM 成本已经明显到需要解释
3. 用户说 AI 回答错了，但你无法复盘当时的输入/上下文/模型
4. 有多轮对话、RAG、Agent、tool call 等多步骤链路
5. 需要按用户、feature、环境统计 LLM 成本和用量
6. 需要比较不同模型、prompt 版本的输出效果
7. 担心 provider rate limit、宕机或区域不可用
8. 需要缓存重复请求来降成本、降延迟
9. 团队里不止一个人维护 LLM 功能，需要共享 dashboard

### 个人使用时的选择逻辑

回到个人使用的场景，这个组合的位置在哪？

ChatGPT 的最终判断和我自己的评估一致：

| 场景 | 更合适的方案 |
|---|---|
| 个人日常使用，统一多模型 API 入口 | AxonHub / Octopus |
| 个人开发者，需要稳定统一调用模型 | LiteLLM 单独 |
| **个人在做 AI 产品 / agent / bot / SaaS** | **Helicone + LiteLLM** |
| 喜欢自托管、一体化面板，不想拆组件 | AxonHub |
| 已经有线上用户、成本和排障压力 | Helicone 很值得上 |

**对我来说，定位很清晰**：我只是个人高频使用，不是在做多用户产品。AxonHub 的一体化体验（网关 + UI + tracing + 成本统计，一个服务搞定）比维护 LiteLLM + Helicone 两个组件更直接。如果以后场景变了，比如需要按用户维度分析成本、需要更完整的 session trace、需要团队共享 dashboard，那时再考虑加 Helicone 也不晚。
