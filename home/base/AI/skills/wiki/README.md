

## 1. Why This Skill

这个 skill 的目标，不是“多存几份 Markdown”，而是给持续性的 topic research 提供一个稳定、可恢复、可压缩的 sidecar 工作流。

普通对话的问题在于：上下文会漂移，历史会被截断，研究过程和结论很容易散掉。普通笔记的问题在于：往往只留下结果，不留下过程、来源和下一步。这个 skill 要解决的，就是 topic 研究过程中最常见的几个问题：

- 研究做到一半中断，下一次很难无损恢复。
- 过程、结论、来源、任务混在一起，越写越乱。
- 一轮轮对话里有价值的内容，没有稳定落点。
- 外部材料、已有笔记、当前讨论之间缺少统一的沉淀方式。

它的核心设计原则是：

- 一个 topic 只保留少量必要文件。
- 每个文件只回答一种问题。
- 默认不复制外部材料，优先保留来源与提炼结果。
- 不把 chat history 当记忆，恢复 topic 时必须先读持久化状态。

## 2. What / When / Where

### What

这是一个面向 `wiki/<topic>/` 的 topic-centered research sidecar skill。

“topic-centered” 的意思是：它不是围绕一次会话组织内容，而是围绕一个长期研究主题组织内容。你研究的是 `lsm-tree`、`marxism`、`history-of-macroeconomics`、`organization-logic` 这样的 topic，不是某一次聊天本身。

### When

适合使用这个 skill 的场景：

- 你准备围绕某个主题持续研究，而不是只问一个一次性问题。
- 你希望这轮研究下次还能无损接上。
- 你希望把“来源、过程、精华结论、待办”分开管理。
- 你已经有一些相关材料，想把它们纳入当前 topic 的研究流里。
- 你希望显式保存某一轮对话摘录，以便后续引用。

不适合使用这个 skill 的场景：

- 只是问一个即时问题，不需要持续沉淀。
- 只是想全文归档一批材料。
- 只是想做通用知识分类或资料搬运。
- 只是想把所有聊天自动保存下来。

换句话说，它不是：

- 自动转录工具
- 全文归档系统
- 通用知识库分类器
- 默认复制外部材料的导入器

### Where

这个 skill 的工作边界非常明确：只操作 `wiki/<topic>/`。

正常使用时，它应当把所有状态都约束在 topic 目录内，而不是到处写。topic 目录以英文 kebab-case slug 命名，例如：

- `wiki/lsm-tree/`
- `wiki/history-of-macroeconomics/`
- `wiki/twitter-ai-image-business/`

## 3. How To Use

这一部分只讲“怎么触发”和“会发生什么”。

### 1. 开始一个 topic

适用场景：你要新开一个研究主题。

示例：

- `用 $wiki 研究 lsm tree write path`
- `用 $wiki 开始研究 marxism`
- `用 $wiki 建一个 history-of-macroeconomics topic`

效果：

- 规范化 topic slug
- 检查对应 topic 目录是否存在
- 如果不存在，就初始化默认结构
- 进入该 topic 的研究工作流

### 2. 继续一个 topic

适用场景：你之前已经研究过这个 topic，现在要续上。

示例：

- `用 $wiki 继续上次的 lsm tree`
- `用 $wiki 继续 history-of-macroeconomics`
- `用 $wiki 接着研究 twitter-ai-image-business`

效果：

- 先读取该 topic 的 `plan.md`
- 再看 `research-log.md` 最近几条
- 再看 `highlights.md`
- 必要时再读最近的 `chat/*.md`
- 在已有状态上继续推进，而不是重新开一轮

### 3. 暂停 / 总结 / 停止

适用场景：这一轮先告一段落，但希望状态被压缩保存。

示例：

- `用 $wiki 暂停当前 lsm tree 研究`
- `用 $wiki 总结我当前对 marxism 的研究进度`
- `用 $wiki stop 当前 topic`

效果：

- 在 `research-log.md` 追加当前轮次总结
- 更新 `plan.md` 的状态流转
- 如果这一轮形成了稳定结论，就更新 `highlights.md`

### 4. [restart] 重启一个 topic

适用场景：你想重新整理一个已有 topic，不再延续当前研究轨迹。

示例：

- `用 $wiki 重新开始 raft log replication`

效果：

- 明确这是一次 restart，而不是普通 resume
- 重新整理当前 topic 的研究起点和任务板

### 5. 引用已有材料

适用场景：你已经有 blog、笔记、文档、书单、旧研究材料，想把它们纳入当前 topic。

示例：

- `用 $wiki 把 blog 里的宏观经济学史学习笔记作为当前 topic 的参考材料`
- `用 $wiki 把这篇论文作为 lsm tree topic 的参考来源`
- `用 $wiki 参考我之前写的组织设计笔记，继续这个 topic`

效果：

- 默认不把材料复制进 topic 目录
- 在 `sources.md` 记录原始路径或 URL
- 在 `research-log.md` 记录你从材料里提炼了什么
- 如果结论足够稳定，再压缩进 `highlights.md`

### 6. [st] 保存上一轮对话

适用场景：上一轮 user / agent 对话本身就值得保留。

示例：

- `用 $wiki save-turn 保存上一轮`
- `用 $wiki st 保存上一轮`

效果：

- 把“上一轮 user turn + agent turn”追加写入 `chat/YYYY-MM-DD-<slug>.md`
- 只在你显式要求时保存

这很重要：`chat/` 不是自动转录目录。只有 `save-turn` / `st` 才会写入。

## 4. Workflow

这个 skill 的推荐工作流可以理解成 5 步。

### 1. Start

确定 topic，规范化 slug，初始化 topic 目录。

### 2. Read State

继续研究前，先读已有状态，而不是直接根据聊天历史硬接：

- `plan.md`
- `research-log.md`
- `highlights.md`
- 必要时 `chat/*.md`

### 3. Research

进行本轮研究，把有效推进记录到 `research-log.md`，把任务变化更新到 `plan.md`。

### 4. Distill

当一轮研究中出现可长期保留的判断时，把它们从过程信息中提炼出来，写进 `highlights.md`。

### 5. Pause or Resume Later

暂停时压缩本轮状态；恢复时从文件状态继续，而不是依赖模型记忆。

这套流程的重点是：

- 过程放在 `research-log.md`
- 任务放在 `plan.md`
- 精华放在 `highlights.md`
- 来源放在 `sources.md`
- 对话摘录只在需要时进 `chat/`

## 5. How It Is Implemented

这一部分才讲文件结构。

### 默认结构

每个 topic 目录默认包含：

- `plan.md`
- `research-log.md`
- `highlights.md`
- `sources.md`
- `chat/`
- `assets/`

### 各文件职责

#### `plan.md`

研究任务板。

固定使用四个顶层分区：

- `## Todo`
- `## Doing`
- `## Done`
- `## Blocked`

当某个分区里已经不只是简单待办，而是有一组相关材料、说明、结论或子记录时，优先用这种结构：

```md
## Done

### 初版框架

- 建立一级分类
- 补入关键说明

### 第一轮资料扫描

- 记录来源
- 补充阶段性判断
```

也就是说，`plan.md` 的顶层仍然是 `Todo / Doing / Done / Blocked`，但各分区内部应优先用 `### <task>` 组织内容，而不是堆一长串平铺 bullet。尤其是 `## Done`，更适合写成一个个完成任务块，后面才能继续往每个 task 下挂相关资料。

它回答的问题是：接下来要研究什么，现在卡在哪里，哪些事项已经完成。

#### `research-log.md`

研究过程日志。

它是 append-only 的时间序列记录，用来保存每一轮有意义的推进，例如：

- 发现了什么
- 依据了什么来源
- 还有什么开放问题
- 下一步打算做什么

它回答的问题是：这个 topic 是怎么一步步推进到现在的。

#### `highlights.md`

精华沉淀。

这里只放高价值、耐时间、值得反复复用的结论或摘要，不放过程噪音，不放临时草稿。

它回答的问题是：关于这个 topic，当前最重要、最稳定的结论是什么。

#### `sources.md`

来源索引。

记录研究过程中真正使用过、值得保留的来源，例如：

- URL
- 本地文件路径
- 书名
- 文档名

每条来源都应该附一句简短说明，解释为什么重要。

它回答的问题是：这些结论从哪里来。

#### `chat/`

显式保存的对话摘录目录。

这里只在 `$wiki save-turn` / `$wiki st` 时写入。它不是自动转录目录，也不是任务板。

#### `assets/`

topic 级别素材目录。

用于保存和该 topic 强相关、但不适合直接写进 Markdown 的本地辅助材料，例如截图、草图、临时图像素材等。

### 为什么没有这些旧文件

#### 没有 `session.md`

因为“当前状态快照”很容易和 `plan.md`、`research-log.md` 重复。恢复 topic 时，直接读现有状态文件通常已经足够。

#### 没有 `notes.md`

因为 `notes.md` 和“精华内容”的边界太模糊，容易越写越泛。这里统一用 `highlights.md` 表达稳定沉淀。

#### 没有 `handoff.md`

因为暂停、总结、恢复时需要的信息，已经可以通过 `plan.md`、`research-log.md`、`highlights.md` 表达，再拆一份 `handoff.md` 只会重复。

#### 没有 `imports/`

因为默认复制外部材料会导致目录膨胀，也会把“来源记录”和“内容副本”混在一起。默认策略改为：

1. 在 `sources.md` 记录原始路径或 URL
2. 在 `research-log.md` 记录提炼结果
3. 在 `highlights.md` 留下稳定结论
