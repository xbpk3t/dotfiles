---
title: Web Access Tools Decision
date: 2026-04-03

---



:::tip[TLDR]

本次只解决“浏览器能力应该怎么接入”这个问题

---

前几天刷twitter，看到 [web-access-tools](https://x.com/sitinme/status/2038571689441890311) 这篇post


<details>
<summary>post原文</summary>

```markdown
刷 GitHub，看到 几个给 AI Agent“接互联网”的开源项目

1.web-access

给 Claude Code 补完整上网能力，它可以直接接管你正在用的 Chrome，连登录态都能复用。你已经登录的小红书、GitHub、各种网站，AI 都能直接进去看。还可以开子 Agent 并行查资料，查多个网站时速度明显快很多。

2.Lightpanda

它是直接从零造了一个给机器用的浏览器。不是 Chromium 魔改，是 Zig 从头写的。
特点：更轻、更快、更适合 Agent。跑大规模网页抓取和自动化时，性能和内存占用都挺夸张，属于那种一看就知道是冲着 Agent 时代来的基础设施。

3.OpenClaw Zero Token

通过浏览器自动化去复用网页端能力，想办法绕开官方 API 付费体系，还做了一个兼容 OpenAI 的网关，能直接接很多第三方客户端。
一句话总结就是：一个项目，尽量把 ChatGPT、Claude、Gemini 这类工具都“白嫖式”串起来。不过这种玩法合规和安全风险都不小，看看思路可以，真上生产得谨慎小心。

4.bb-browser

通过扩展 + CLI + MCP，把真实浏览器直接变成 Agent 的操作入口。很多常用网站都已经做好适配，AI 想搜内容、看社区、翻新闻，基本开箱就能跑。

```

</details>



---


今天来做个evaluation，本文就是该选型过程的record

最终决定只安装 `bb-browser`

具体决策过程如下

:::



## 【技术选型】对相关工具的基本认知


https://github.com/eze-is/web-access

https://github.com/tinyfish-io/tinyfish-cookbook


---

- `web-access` / `bb-browser`：和 `agent-browser` 最接近，都是“让 agent 操作真实浏览器”的上层入口，只是它们更偏 MCP / browser-extension 接入。
- `TinyFish MCP`：更偏“联网研究 / 网页抓取 / 结构化返回”的 MCP，不一定强调真实 DOM 交互、表单点击、登录态页面操作。
- `Lightpanda`：更像底层浏览器 runtime / 基础设施，不是你直接往 catalog 里放的那种 end-user skill。
- `OpenClaw Zero Token`：方向更像“网页端能力复用 + 网关旁路”，不只是 browser automation，而且合规/安全边界明显更差。


如果按“功能上是不是同类”来分：

- 第一类，真实浏览器交互：`agent-browser`、`web-access`、`bb-browser`。
- 第二类，网页研究/抓取：`TinyFish MCP`。
- 第三类，底层基础设施：`Lightpanda`。
- 第四类，灰色绕路/网关方案：`OpenClaw Zero Token`。





## 具体决策过程


### 首先排除掉 Lightpanda 和 OpenClaw Zero Token


#### Lightpanda

- 不再继续讨论。
- 原因：它更像底层浏览器 runtime / infra，而不是当前 dotfiles 里要接入的 agent-facing MCP 入口。
- 它解决的是“浏览器底层实现效率”问题，不是“给当前 agent 环境补一个长期主力浏览器入口”问题。

#### OpenClaw Zero Token

- 不再继续讨论。
- 原因：它的主要卖点并不是“浏览器能力抽象得更好”，而是带有明显灰色边界的网页端复用/旁路思路。
- 这类方案天然带来合规、稳定性和维护风险，不适合当前仓库追求的长期可维护能力栈。




### 这类 web-access 应该用 MCP 还是 skill?

- `skill` 是 workflow 层：定义什么时候用、怎么用、失败时怎么回退。
- `MCP` 是能力层：把浏览器本身作为长期可复用工具暴露给 agent。


浏览器属于基础能力，而不是单一 workflow。

因此这次应该优先决定“能力层接什么”，再决定以后是否还要叠加 browser skill。

所以排除掉 `agent-browser` 和 `web-access` 这两个skill



### TinyFish MCP 与现有 `mcp-servers.nix` 的关系


```markdown
https://www.tinyfish.ai/

TinyFish MCP，这个我觉得挺好，它能让 Claude 直接上网浏览、抓取网页、做资料调研，还能返回结构化结果，不只是给一段静态回答。我最近会拿它来给自己的周刊找 AI 新闻，比如抓最近几小时 Hacker News 上比较热门的内容，再整理成一份干净的摘要列表，效率很高。
```

---

现有相关能力：

- `ddg`
    - 搜索入口。
- `chrome-devtools`
    - 通用浏览器调试、页面观察、DOM 交互。
- `octocode` / `deepwiki`
    - repo / GitHub 研究。

判断：

- `TinyFish MCP` 与现有配置存在部分重叠，但不等价。
- 它更像“研究型网页 MCP”，不是“真实浏览器控制 MCP”。
- 只有在你明确经常做网页调研、结构化抓取、新闻/资料汇总，而且嫌 `ddg + chrome-devtools` 组合太散时，它才值得补。
- 当前没有必要与 `bb-browser` 一起同时引入。






## 具体实现


基于以上排除，最终在 `web-access` 和 `bb-browser` 这两个同类MCP里，选择了后者


---

- 在 [`home/base/tui/AI/mcp-servers.nix`](home/base/tui/AI/mcp-servers.nix) 中新增 `bb-browser`
- 暂不将 `agent-browser` 放入 `home/base/tui/AI/skills-catalog.nix`
- 暂不引入 `TinyFish MCP`
