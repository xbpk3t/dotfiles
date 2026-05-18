---
title: AI-Agent-Cockpit 技术选型复盘
description: 一次关于 cmux、tmux、Zellij、OpenSessions 与 tmux-agent-sidebar 的 AI agent cockpit 技术选型复盘。
tags:
  - LLM
  - tmux
isOriginal: true
---


:::tip[TLDR]

> ***Why Cockpit?***

在“AI编程时代”，同时跑3、4个Agent同时开发，是日常。同时跑6、7个Agent也是隔三差五。那么就需要一个用来提示各个Agent状态的工具。

我的日常IDE就是goland，一直都是直接用 `Goland Terminal`。跟大部分人一样，左中右layout分别是文件树、代码区、Terminal，非常舒服的搭配。

但其实这么处理也有个问题：***右侧的 Terminal和Structure需要经常切换***

但是在“AI编程时代”，这种layout又有一些新问题：

***核心在于没有notification***。需要自己在term里逐个tab去翻究竟哪个agent处理好了，就很麻烦。类似于我们linux网络模型里同步和异步的区别，现在这个模式就是同步，“我只要不问，你就不告诉我”，需要自己去查；用了 `cockpit`之后有了notification，就相当于异步，有个事件机制。很浅显的东西。这是最核心的。

如果只是轻量vibe-coding还好，但是最近对用量上来了（最近一周平均每天都是2E左右的token消耗），就感觉以往的这套东西，到了非变不可的时候了。所以也就做了相应探索，有了这篇blog。


---


> ***这里有几个关键决策：***

这是我整个决策过程中提炼出的关键分叉点：

~~这不是"哪个工具最强"的横评。它是一次技术选型复盘：先明确真正的问题，列出不可妥协的约束，再比较候选方案，最后得到一个有边界的工作流选择。结论只对我的约束成立。~~


```markdown
1. 用cmux这种APP还是 mux插件？
   → cmux体验很好，OOTB产品，但是只在mac可用，相关经验不复用、要打折。并且我希望可以直接在goland terminal里使用，而非来回切换。
   → 选 mux 插件方案

2. mux插件方案：用tmux还是zz？
   → 我更喜欢 zz，但 AI agent 生态（Claude Code Agent Teams）更偏 tmux
   → 选 tmux

3. tmux方案：用 OpenSessions 还是 tmux-agent-sidebar？为了desktop notification，所以选择 后者
   → 我需要 desktop notification，OpenSessions 不擅长
   → 选 tmux-agent-sidebar

4. tmux 不顺手，能否切回 zz？
   → 试了 claude-code-zellij-status（无桌面通知）和 zellaude（配不通）
   → 回到 tmux
我用tmux不顺手，想用zz，但是zz目前在这方面生态很差（且“Agent Teams 只支持 tmux”、“Claude Code 目前使用 tmux 作为 Agent Teams v2.1.32+ 唯一支持的终端复用器”）


5. 选择zz，用claude-code-zellij-status 还是 zellaude？
   -> 最终转回tmux，对几种tmux方案做了比较，最终选择优化 `tmux-agent-sidebar`，以满足我的需求
   -> 我没用 claude-code-zellij-status，因为我确实需要桌面通知。我尝试了 zellaude，配置有问题，尝试让3个model都帮我配置，确认用不成，所以也不考虑。

```


***我判断最理想的方案：直接在goland里在terminal的tab里用mux，并且需要提供 desktop notification机制。***


---


:::


---

## 关键决策

以下是我在这次选型中经历的关键分叉点。注意这些决策在当时看似合理，但最终实际落地时走了另一条路——详见文末。

### 需求重新定义：我不是要 AI IDE，而是要 agent observability

一开始我以为自己在找"AI 编程时代的工具"——哪个 IDE 的 AI 能力更强？哪个 agent 写代码更厉害？哪个工具最 AI-native？

但讨论下来发现，真正的问题其实是：

```text
当前有哪些 agent 在跑？
哪个 agent 需要我 approve？
哪个 agent 已经完成了？
哪个 agent 出错了？
我能不能不用盯着一堆 terminal？
```

所以这次选型的目标不是 AI IDE，而是 **agent observability**。具体来说：

```text
agent 状态可见
→ agent 需要处理时提醒
→ agent 完成时提醒
→ 能快速跳回对应 terminal
→ 不破坏原有开发工作流
```

这也是为什么单纯比较 Cursor、Zed、GoLand AI Assistant 或 Claude Code Desktop，并不能解决我的核心问题——它们解决的是"AI 怎么参与代码编辑"，而我当时真正缺的是"多个 CLI agent 怎么被观察和调度"。

Claude Code Desktop 曾短暂被考虑。它的局限是只适合 Claude Code-only 场景，不适合统一管理 Codex CLI + Claude Code CLI 双主力。再加上基于 Electron 实现，我不想引入又一个非原生 desktop app，所以也排除了。

---

### cmux：体验很好，但产品形态不理想

cmux 是最早认真考虑的方案。它的优点非常直接：

```text
OOTB，产品化程度高
sidebar / notification / unread ring 完整
适合同时跑 Claude Code / Codex / OpenCode 等 CLI agents
不需要先学习 tmux
```

如果只看功能，cmux 很符合"agent cockpit"这个需求。但它的问题也很清楚：

```text
cmux 是独立 App
→ 主要只在 macOS 上可用
→ 不是 Ghostty 本体
→ 引入自己的 workspace / pane / surface 心智模型
→ 我需要在 GoLand 和 cmux 之间来回切换
→ 相关经验不容易复用到其他 mux / terminal 生态
```

cmux 不是不好用。问题是它不是我最想要的产品形态。

我理想中的形态是：

```text
GoLand Editor + GoLand Terminal + mux + agent sidebar / notification
```

而不是：

```text
GoLand + 另一个独立 agent terminal app
```

所以从"独立 App"转向了"mux 插件"。

---

### 从 App 到 mux 插件：为什么我想把 agent cockpit 放进 GoLand Terminal

cmux 最大的问题，不是功能问题，而是工作流边界问题。

我的代码主场是 GoLand：

```text
看代码、review diff、debug、refactor、test runner、project search、local changes
```

如果 agent cockpit 在另一个 App 里，就会变成 GoLand 里看代码、cmux 里处理 agent，两个地方来回切换。这个方案可以用，但不是最理想。

我更想要的是：

```text
GoLand
├── Editor：看代码 / 改代码 / review diff
└── Terminal：跑 mux / Claude Code / shell / logs
```

这样有几个好处：

```text
不离开 GoLand 主窗口
agent session 和代码上下文更接近
desktop notification 负责提醒我回来处理
mux 只是 terminal 内的一层 session 管理
```

所以问题变成了：哪个 mux + 插件生态，能在 GoLand Terminal 里管理 AI agent sessions 并提供 desktop notification？

---

### tmux vs zz：我更喜欢 zz，但生态把我推回 tmux

我原本更喜欢 zz / Zellij。原因很简单：zz / Zellij 的 tab / session 感更自然，我已经习惯 zz，tmux 对我来说不顺手。但是 AI agent 生态当前明显更偏 tmux。

有一个容易误读的点：

:::warning

"Claude Code 目前使用 tmux 作为 Agent Teams 唯一支持的终端复用器"——这并不是说普通 Claude Code 只能在 tmux 里运行。

普通 Claude Code 在 Ghostty、Zellij、GoLand Terminal 里都能跑。这里说的是 Claude Code 的 Agent Teams / teammate panes / terminal multiplexer integration，当前主要围绕 tmux。

:::

换句话说，普通 Claude Code 不依赖 tmux，但 Agent Teams split-pane / teammate terminal support 当前 tmux 生态更成熟。我在 Zellij 方向看了几个方案：

```text
zellij-claude-teams：用 fake tmux shim 让 Agent Teams 在 Zellij 里开 pane
zellaude：Zellij + Claude Code 状态/notification/click-to-focus
claude-code-zellij-status：基于 zjstatus 的 status bar 状态显示
zellij-attention：最轻量，只做 waiting/completed attention marker
```

这些工具各自解决一部分问题，但没有一个在我的实际约束下完全跑通。

GitHub 社区也有类似声音——[有用户反映](https://x.com/xxm459259/status/2042147729007341837)尝试了 cmux/conductor 等方案后，最终也"全部放弃叛逃到 tmux 插件方案"。

最终我不得不承认：我更喜欢 zz / Zellij，但当前 AI agent 生态把我推回了 tmux。这不是"tmux 更好用"的结论，而是"tmux 生态更成熟"的结论。

---

### OpenSessions vs tmux-agent-sidebar：desktop notification 改变了选择

:::tip

注意二者的核心区别在于notification的事件机制不同


OpenSessions 是 watcher-driven

tmux-agent-sidebar 是 hook-driven


显而易见的，后者更好

:::


在 tmux 生态里，我重点比较了 OpenSessions 和 tmux-agent-sidebar。它们都在解决类似问题——tmux sessions / panes → agent 状态聚合 → sidebar 展示 → 快速跳转——但思路不同。

**OpenSessions** 更像通用 session manager + agent watcher + sidebar + repo breadcrumbs。

它的优点：

```text
更通用，更像 session overview
watcher-driven，相对旁路，不侵入 Claude / Codex hooks
有 HTTP metadata API
```

但它的问题是 desktop notification 不是强项：

```text
/notify 更像 sidebar / log 高亮
没有一个直接的 OS-level notification 体验
agent event sink / notifier plugin 也不够直接
```

**tmux-agent-sidebar** 是专门的 Claude Code / Codex / OpenCode agent monitor。

它的优点：

```text
hook-driven，状态更实时
Claude Code 语义更准
支持 desktop notification
能处理 stop / notification / stop_failure / permission 等事件
更像专门为 AI agent 做的 tmux sidebar
```

缺点也明显：

```text
更侵入，要配置 hooks
UI 默认像监控面板（左侧 sidebar + 底部 Activity/Git panel）
tmux 本身我不顺手
```

但我当时的核心需求里，desktop notification 是不可妥协的。所以：

```text
OpenSessions 更优雅
tmux-agent-sidebar 更对症
```

两者的底层机制也不同：

```text
tmux-agent-sidebar = hook-driven push model
→ 用 hooks 拿高保真事件（SessionStart / UserPromptSubmit / Stop / Notification / PermissionDenied 等）

OpenSessions = watcher-driven pull model
→ 读取 transcript/session files（~/.claude/projects/*.jsonl 等）
```

关于 hook 是否占 context：hook 本身不等于 context 污染。只有某些 hook 的 stdout / additionalContext 会进上下文。如果 hook 只做状态采集、notification、写 tmux options，stdout 保持空，不会明显占 context。真正风险是 hook 配置的侵入性和 agent 升级兼容性。

#### 回到 tmux-agent-sidebar：为什么最终选择它

但我第一次看到 tmux-agent-sidebar 的默认 layout 时并不喜欢：

```text
左侧 sidebar 占空间
底部 Activity / Git panel 信息密度低
不像 zz / Zellij 那种 tab 感
默认像一个常驻 dashboard
```

所以最终思路不是照单全收它的默认体验，而是把它改造成：

```text
按需打开的 agent inspector
+
desktop notification layer
```

也就是说：

```text
平时 sidebar 隐藏
只靠 notification 提醒
需要看 agent 状态时才打开
看完就关闭
GoLand 仍然是主工作区
```

---

### Zellij 方向的尝试：claude-code-zellij-status 与 zellaude

既然原本更喜欢 zz / Zellij，我也看了 Zellij 方向。重点是两个：claude-code-zellij-status 和 zellaude。

**claude-code-zellij-status**

基于 zjstatus（我已经在用），能融入现有 Zellij status bar：

```text
优点：状态符号比较细，对 Claude Code 状态有一定支持，能融入已有 zjstatus
问题：没有明确满足 desktop notification 需求，更像 status bar 状态显示，不是完整 attention layer
```

**zellaude**

更接近我想要的 Zellij 方案：

```text
Zellij-native，Claude Code 状态足够丰富
有 desktop notification 和 click-to-focus / smart pane focus
有 permission flash
```

但我实际尝试配置失败，甚至让多个模型帮我配置，最后确认当前环境跑不通，所以也暂时放弃。

这里不是说 zellaude 不行。更准确的说法是：zellaude 看起来方向正确，但在我的当前环境里没有配置成功，所以不能作为主方案。

---

## tmux-agent-sidebar 的使用

> 以下是我在使用 tmux-agent-sidebar 期间总结的使用方式。虽然最终换回了 cmux，但这些思路（按需 inspector、notification 优先）对任何 agent cockpit 方案都通用。

### 心智模型：它不是工作区，而是 agent 雷达

我不打算把 tmux-agent-sidebar 当成常驻工作区。它更像一个 agent 雷达：

```text
平时隐藏 → agent 完成/需要处理时发 notification
→ 打开 sidebar 看状态 → 跳到对应 pane
→ 处理完关闭 sidebar
```

它不是新的主工作区或代码编辑环境，只是补上缺失的那一层：agent status + desktop notification + quick jump。

日常结构：

```text
GoLand
├── Editor / Diff / Test Runner
└── Terminal tab
    └── tmux session
        ├── window: agent-auth  [Claude Code + shell]
        ├── window: agent-payment [Claude Code + shell]
        └── tmux-agent-sidebar (按需打开)
```

### 日常启动与操作

每天开始工作：

```bash
tmux attach -t agents || tmux new -s agents
```

建议固定 session 名为 `agents`，进入后 sidebar 默认隐藏。

### 新建一个 agent 任务

一个 agent 任务对应一个 tmux window。创建一个 window 后重命名：

```text
ai-auth / ai-payment
bug-timeout / review-123
```

进入对应目录启动 Claude Code：

```bash
cd ~/code/project-ai-payment && claude
```

给任务时明确边界，例如：实现某个功能、不改变 public API、补 table-driven tests、完成后总结 diff 和测试结果。

### agent 运行期间：不要盯着它

Claude Code 跑起来后回 GoLand editor 继续工作，等 desktop notification。tmux-agent-sidebar 的存在意义就是让你不用盯。

### 收到 notification 后

```text
notification → 回 GoLand Terminal → 打开 sidebar
→ 选择对应 agent → 跳到 pane
→ approve / reject / 查看结果 → 关闭 sidebar
```

sidebar 只负责定位，不负责做判断。真正判断还是在 Claude pane 里完成。

### 完成后：回到 GoLand review diff

不要直接 merge。Claude 完成后回 GoLand 看 Local Changes review diff，跑测试，决定 commit / 修改 / 丢弃。不为了"一切在 terminal 里"而用 tmux review 大 diff。

### 多 agent 并行时的窗口组织

```text
session: agents
├── window 1: ai-auth      [Claude Code + shell]
├── window 2: ai-payment   [Claude Code + shell]
└── window 3: ai-cleanup   [Claude Code + shell]
```

一个 agent 任务一个 window。每个 window 里先只开 Claude Code，需要时再 split 一个 shell pane。不要一开始把 layout 搞复杂。

### 推荐配置

```tmux
# Keep sidebar narrow.
set -g @sidebar_width '10%'

# Hide bottom Activity/Git panel.
set -g @sidebar_bottom_height '0'

# Do not automatically create sidebar in every window.
set -g @sidebar_auto_create 'off'

# Keep desktop notifications enabled.
set -g @sidebar_notifications 'on'

# Keep notification noise reasonable.
set -g @sidebar_notifications_events 'stop,notification,stop_failure'
```

### 不建议的用法

- 不建议常驻 sidebar——只跑 1～2 个 agent 时信息密度太低
- 不建议把 tmux 当主代码工作区——nvim/helix 对我来说不如 GoLand
- 不建议依赖 GoLand Terminal 的 OSC passthrough 做 notification——GoLand Terminal 不一定支持 Ghostty 那种 passthrough 行为。notification 应走 Claude Code hook → tmux-agent-sidebar → osascript → macOS Notification Center

---

## 总结 / 反思

:::tip[TLDR]

这次eval，总体来说还是挺耗时的

我在想，***怎么才能有效压缩eval的耗时，提高效率？***

*也就是说方法论层面，而非只针对本次eval本身过程的方法*

---

这次 eval 耗时很长，复盘来看主要因为几个问题串在一起：

1. **问题定义绕路了**——一开始比的是"哪个工具更强"，而不是"我的工作流缺什么"，导致 cmux → OpenSessions → tmux-agent-sidebar → Zellij → 回到 cmux，绕了一大圈。

2. **没设置止损条件**——每个方案都试到"彻底确认不行"才放弃。如果一开始给每个方案设 1～2 天限时实验 + 明确成功标准，至少省一半时间。

3. **喜欢的 ≠ 能跑通的**——Zellij 方向耗了不少时间，最后要么缺 notification、要么配不通。如果早认清"当前 AI agent 生态更偏 tmux"这个约束，可以直接跳过这个分支。

---

以上3点虽然总结了问题，但还是偏事后分析，不够"方法"。

下面把这个经验工具化成一个 Prompt 模板，下次再做类似选型时直接填空，扔给 ChatGPT DeepResearch。

> 工具选型 Prompt 模板

遇到需要从多个候选方案中做选择的问题时，复制下方模板填空后发给 DeepResearch：

```markdown
## 技术选型需求

**核心目标：** 解决 [填写：要解决的核心问题]，不是 [填写：容易混淆的错误目标]。

**硬约束（不可妥协）：**
- [填写：硬约束 1]
- [填写：硬约束 2]
- [填写：硬约束 3]

**已排除方案及理由：**
- [方案 A] → 排除理由：[填写]
- [方案 B] → 排除理由：[填写]

**待选方案：**
- [方案 A]
- [方案 B]
- [方案 C]

**比较维度：**
1. 工作流适配度（是否破坏现有工作流）
2. [填写：维度 2]
3. [填写：维度 3]
4. 生态成熟度
5. 降级路径

**评估规则：** 每个方案限时 [填写：天数] 评估，满足成功标准即视为选型完成，不追求"最好"。
```

具体到本次选型，填完是这样的：

```markdown
## 技术选型需求

**核心目标：** 解决 AI agent 的状态可观测性，不是 AI IDE。
**硬约束：** GoLand 是主 IDE、需要 OS-level desktop notification、不想迁移到 nvim/helix。
**已排除方案：** Claude Code Desktop（Electron + 只支持 Claude-only）。
**待选方案：** cmux / tmux-agent-sidebar / Zellij+zellaude / OpenSessions。
**比较维度：** 工作流适配度、notification 完整性、生态成熟度、维护成本。
**评估规则：** 每个方案限时 2 天评估，满足即停止。
```

:::

### 技术选型不是比工具，而是比工作流

这次选型一开始很容易陷入"哪个工具更强"的比较——cmux vs OpenSessions、OpenSessions vs tmux-agent-sidebar、tmux vs zz、zellaude vs claude-code-zellij-status。但最后发现，更重要的问题是：我的主代码工作在哪里？agent 在哪里跑？notification 从哪里来？出问题时怎么降级？这个工具会不会破坏我已有工作流？

技术选型不是功能表对比，而是工作流对比。

### 先找不可妥协项

这次真正的不可妥协项是：GoLand 仍然是主 IDE、需要 desktop notification、最好能在 GoLand Terminal 里使用、不想为了 agent dashboard 迁移到 nvim/helix、不想长期依赖独立 macOS-only app。这些约束越早明确，选型越快。如果一开始就写清楚，可能不用绕这么大一圈。

### 区分喜欢的工具和成熟的生态

我更喜欢 zz / Zellij 的交互，但当前 Claude Code / Agent Teams / agent notification 生态明显更偏 tmux。最终选择 tmux，不是因为我喜欢它，而是因为它更能跑通。这也是技术选型中很常见的问题——我喜欢的工具 ≠ 当前生态最成熟的工具。这次我选择了生态成熟的一边。

### 用限时实验避免 endless research

这次决策流程很长。下次类似选型，应该更早设置限时实验：给每个候选方案最多 1～2 天，明确成功标准（是否能在主 IDE 内使用、是否有可靠 desktop notification、是否能管理 3+ agent、是否不破坏原有工作流），不满足就下一个。这样能避免陷入无休止工具比较。

### 更好地让 GPT 做选型

如果一开始就明确告知硬约束和不可妥协项，GPT 能更快抓住问题核心，而不是泛泛比较工具。更好的 prompt 模板：

```text
我想解决的是 AI agent observability，不是 AI IDE。
我的主 IDE 是 GoLand。
我希望 agent cockpit 在 GoLand Terminal 里。
我需要 desktop notification。
我不想迁移到 nvim/helix。
候选方案是 A/B/C。
请按工作流、notification、生态成熟度、维护成本、降级路径比较。
```




## 最终还是用回了cmux [2026-05-18]

因为我真就是tmux苦手，zz我是能日常使用的，但是感觉tmux的DX比zz还差不少。一个复制文本，弄了半天才搞定。并且经过查证，这个 `tmux-agent-sidebar`的UI也无法修改，在goland的Terminal里使用，并不舒服（layout问题，会导致agent本身的编辑区很小，这玩意归根到底还是需要比较大的屏幕面积的）。

另外我想了一下，其实之前想要的“直接在goland里在terminal的tab里用mux”，并非最优解。我平时在goland里也是同时开2、3个项目（但是倒也未必同时开发），但是这么一来，即使有notification，也要在这2、3个项目之间翻找。远不如直接在 cmux 里直观。

所以做了 [feat(LLM/cockpit)](https://github.com/xbpk3t/dotfiles/commit/ae42d3f71983a29987c1c8c1266959faaf5f899b)

直接用 cmux 替代了 ghostty，作为本地唯一的 Terminal APP

至于一开始担心的：“cmux相关经验不复用、要打折”之类的，感觉其实也没有那么重要，当下的开发体验更重要，不是吗？折腾半天 tmux/zz 插件之类的，还不如直接用cmux来的爽快直接。

兜兜转转还是回到了原点，但是这次探索并非没有意义。基本上摸清了目前 `AI-Agent-Cockpit`的生态，以及几种主流工具的实现机制。
