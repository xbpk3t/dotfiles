---
title: Markdown-first SSG技术选型review
date: 2026-04-08
isOriginal: true
---



:::tip[TLDR]

***需求很明确：不需要引入整个blog站点，直接用md文件来render出blog站点***

先后尝试了 `MkDocs`, `Zola`, `Hugo`, `mdBook`，最终选择就 `Zola` 做进一步探索。

之后找了几个 Zola 的 theme（先后尝试了 Tanuki, Abridge 这两个theme），尝试先mock几个demo md文件，把 Zola 跑起来，完成后来接入整个 `docs folder` 的内容开始全量测试。

***最终的卡点还是在于，从 DFM (Docusaurus flavor Markdown) 转换到 Zola 使用的 `CommonMark/GFM`，非常麻烦***。无论是直接手写 wrapper，还是用 `pandoc` 内置的各 `Markdown Flavor`转换，都很麻烦。

最终还是选择了直接通过给我现有的基于 Docusaurus 的 blog里，再添加一个 dotfiles 的 blog instance 即可。在 CI 里直接用 `fetch` 拉到这个 `dotfiles/docs` folder，然后直接 render 即可。具体查看 https://blog.lucc.dev/dotfiles

当然这个方案的优缺点都是显而易见的，优势在于可以不需要再做麻烦复杂（甚至没有意义）的 DFM -> GFM 的 wrapper，劣势则在于因为 `dotfiles/docs` 跟 `blog` 没有天然集成在一起，所以这个 `dotfiles/docs` 是否真的能render出来，并不确定，我们想要在本地验证这点，也有点麻烦。当然，我知道本地验证其实很简单，但是这种脱节的感觉就是有点奇怪（不像 `mdBook` 的感觉那么好）

:::



## 背景（需求+约束）

本次讨论的目标，是给当前仓库里的 `docs/` 内容找一个“可直接发布为网站”的方案。

核心约束是：

- 1、*在repo里的 `docs` 里，只需要存放相应 md文件，不需要放一个完整的常见的 `Docusaurus`, `VitePress` 等常用项目文档SSG* 这点要求通常有以下特征：
  - 不想单独再维护一个完整站点工程
  - 直接把仓库里的 docs/ 当内容源
  - 主要依据 md 文件和目录结构来生成站点
  - 尽量少引入前端框架、复杂构建壳子
  - 在 CI 里完成构建，然后发布到 Cloudflare Pages 之类的平台。
- 2、【Md-flavor兼容】从我习惯且常用的 `DFM`转换到`GFM`，可以直接渲染









## 讨论和尝试过的方案

### 1. MkDocs + Material for MkDocs

最开始认为 MkDocs 的展示效果更接近想要的“好看文档站”。

评估结果：

- 优点：
  - 文档站体验成熟，目录、搜索、阅读感比较强。
  - 作为 docs portal 的默认观感通常比很多 SSG 更完整。
- 问题：
  - 现有 Docusaurus 语法不能直接无缝兼容。
  - Material 进入 maintenance mode，长期演进确定性下降。
  - 如果坚持“不改原始 Markdown”，仍然需要 build 阶段的兼容转换层。

结论：

- 不是不能用，但会把内容层更明显地绑定到 MkDocs / Python-Markdown 生态。
- 最终没有继续走这条路。

### 2. Zola

后续把重点转到了 Zola。

最初判断 Zola 的原因：

- 工具链轻，单二进制。
- 适合 Markdown 内容站。
- 支持 CI 构建和静态部署。

中间澄清过一个误解：

- 误以为 Zola 只能用 `+++` TOML front matter。
- 实际上 Zola 也支持 `---` YAML front matter。

但后续发现真正的问题不在 front matter，而在内容模型：

- 需要 `_index.md` 表示 section。
- 现有 `README.md` 语义需要映射。
- 仍然需要处理 topic / page / section 的站点结构。

结论：

- Zola 仍然是可行方案。
- 但它并没有“天然无痛吃下现有 docs/”。
- 后续继续讨论时，仍然把它当成最现实的候选之一。


---

***并且 zola 不支持 plantuml 之类的 diagram 渲染。***



### 3. Hugo

在意识到 Zola 也需要 `_index.md` / section 语义之后，开始怀疑 Hugo 是否更适合。

评估结果：

- Hugo 同样支持 YAML front matter。
- Hugo 的内容组织能力和主题生态更成熟。
- 但 Hugo 也并不会自动消除 `_index.md` 和内容结构映射问题。
- 真正的变量不在 front matter，而在：
  - 主题是否足够轻
  - 是否会引入 npm / Tailwind / 额外工具链

结论：

- Hugo 是值得继续评估的候选。
- 但并没有因为 front matter 就自动优于 Zola。
- 本次没有继续深入到 Hugo theme 的落地验证。

### 4. mdBook

[rust-lang/mdBook](https://github.com/rust-lang/mdBook)

> 其实 `mdBook` 完美契合我的核心需求（只需要 md files），但是问题同样也很大：本身就是 `Gitbook` 的替代品，从形态来说，天然跟我的需求不匹配，并且也会有上面所说的 Markdown Flavor 不支持问题。所以最终排除掉该方案。

---

结论比较明确：

- `mdBook` 更适合“书 / 教程 / 线性章节”。
- 你的内容模型更像“topic + dated notes + review archive”。
- 它依赖 `SUMMARY.md` 这类书籍式组织方式，不适合当前 `docs/` 的实际结构。

因此：

- `mdBook` 并不比 Zola / MkDocs 更贴合当前需求。
- 很快被排除。



## Docusaurus Markdown 兼容问题

这是整个话题里真正的主难点。

当前 `docs/` 里实际存在的关键语法包括：

- YAML front matter
- `:::tip` / `:::warning` / `:::danger` / `:::caution` 等 Docusaurus admonition
- 少量 `<details>`
- 一些 `README.md` 入口页
- 一些 `.md` 内链

评估过程中讨论过两条路：

### 1. 手写 wrapper / 兼容层

之前的判断是：

- 无论是 MkDocs、Zola 还是 Hugo，只要不直接修改原始 Markdown，就大概率需要 build 阶段的兼容层。

### 2. Pandoc first pass

后面又提出一个更激进的方向：

- 直接拿真实 `docs/`
- 用 `pandoc` 做第一轮转换
- 把输出放到新的隔离目录
- 再交给 Zola 实际 render
- 遇到 render 不了的点，再在 wrapper 里补

这条思路被认为是“最快接近真实成本”的方式，因此开始执行。

## Pandoc 真实试验的结论

后来已经开始对真实 `docs/` 做 Pandoc 试验。

确认到的事实：

- `pandoc` 可以读 YAML front matter。
- `pandoc` 可以读 `:::` 风格的 fenced div。
- 但对 Docusaurus admonition 的理解并不完整。

具体表现：

- `:::tip[TLDR]` 会被 Pandoc 解析成普通 div。
- 输出类似 `<div class="tip[TLDR]">`，而不是目标站点能直接优雅显示的语义结构。
- 这说明 Pandoc 可以作为 first pass，但不能完全替代后续兼容层。

另外还出现了一些额外现象：

- Pandoc 输出里出现了不希望要的内容噪音。
- Pandoc 转完后的内链和 section 语义，仍然不等于 Zola 可直接用的最终结构。

结论：

- Pandoc 有价值。
- 但“Pandoc 一步到位解决全部兼容问题”的预期并不成立。




## 为什么最后决定放弃当前话题

最终并不是因为某一个方案“完全不可行”，而是因为以下几点叠加：

- 没有任何一个方案能“完全零成本接入现有 docs”。
- 真正的难点不在站点壳子，而在 Docusaurus Markdown 变体和站点内容模型之间的映射。
- 即使 theme 选型收敛到 Zola + Abridge，后续仍然需要继续投入在：
  - `README.md` / `_index.md`
  - admonition 语法
  - 内链改写
  - section / page 组织
- Pandoc 虽然有帮助，但也没有直接把兼容问题清空。

因此最后的实际状态是：

- 方向大致收敛到了 `Zola + Abridge + Pandoc first pass`
- 但尚未进入一个“低风险、低成本、值得立即继续”的阶段
- 所以当前选择直接结束这个话题

## 如果以后重开，可以从哪里继续

如果未来重新启动这件事，最合理的切入点应当是：

1. 继续基于 `demo/zola-abridge-import`
2. 直接对真实 `docs/` 做 Pandoc first pass
3. 用 Zola build / check 抓出实际失败点
4. 只为失败点补最薄的 wrapper
5. 最后再决定是否值得正式接入主仓库发布链路

换句话说，后续如果要继续，不应该再回到“纯概念比较”，而应该直接进入：

- 真文档
- 真转换
- 真渲染
- 真失败点收敛



## 相关知识点


### 目前 Markdown 有哪些 flavors?


```yaml
- Flavor: CommonMark
  标准化程度: ✅（最高，正式规范）
  表格支持: ❌
  任务列表: ❌
  删除线: ❌
  脚注: ❌
  定义列表/缩写: ❌
  数学公式: ❌
  自动链接: ❌
  元数据/YAML: ❌
  生态/采用度: ✅（基础标准，高兼容）
- Flavor: GFM
  标准化程度: "✅（基于 CommonMark）"
  表格支持: ✅
  任务列表: ✅
  删除线: ✅
  脚注: ❌
  定义列表/缩写: ❌
  数学公式: ❌
  自动链接: ✅
  元数据/YAML: ❌
  生态/采用度: "✅（GitHub 等平台极高）"
- Flavor: Docusaurus
  标准化程度: "⚠️（支持 CommonMark + MDX）"
  表格支持: ✅
  任务列表: ✅
  删除线: ✅
  脚注: ⚠️
  定义列表/缩写: ⚠️
  数学公式: ✅（KaTeX）
  自动链接: ✅
  元数据/YAML: ✅
  生态/采用度: ✅（文档站点专用，高）
- Flavor: "Markdown Extra"
  标准化程度: ⚠️（早期扩展，无严格规范）
  表格支持: ✅
  任务列表: ❌
  删除线: ❌
  脚注: ✅
  定义列表/缩写: ✅
  数学公式: ❌
  自动链接: ❌
  元数据/YAML: ❌
  生态/采用度: ⚠️（中等，老项目常见）
- Flavor: MultiMarkdown
  标准化程度: ⚠️（丰富但无统一规范）
  表格支持: ✅
  任务列表: ⚠️
  删除线: ⚠️
  脚注: ✅
  定义列表/缩写: ✅
  数学公式: ✅
  自动链接: ⚠️
  元数据/YAML: ✅
  生态/采用度: ⚠️（学术/写作工具）
- Flavor: "Pandoc Markdown"
  标准化程度: ⚠️（灵活扩展）
  表格支持: ✅
  任务列表: ✅
  删除线: ✅
  脚注: ✅
  定义列表/缩写: ✅
  数学公式: ✅
  自动链接: ✅
  元数据/YAML: ✅
  生态/采用度: ✅（转换工具王者，多格式）
- Flavor: "GitLab FLM (GLFM)"
  标准化程度: "✅（基于 CommonMark + GFM）"
  表格支持: ✅
  任务列表: ✅
  删除线: ✅
  脚注: ⚠️
  定义列表/缩写: ⚠️
  数学公式: ⚠️
  自动链接: ✅
  元数据/YAML: ❌
  生态/采用度: "✅（GitLab 平台高）"
- Flavor: kramdown
  标准化程度: "⚠️（Ruby 扩展）"
  表格支持: ✅
  任务列表: ⚠️
  删除线: ✅
  脚注: ✅
  定义列表/缩写: ✅
  数学公式: ✅
  自动链接: ⚠️
  元数据/YAML: ⚠️
  生态/采用度: "⚠️（Jekyll 等 Ruby 生态）"

```


结论：


- 如果追求最大兼容性和一致性，优先 CommonMark（作为基础）。
- 日常 GitHub/开源项目用 GFM 最方便。
- 写技术文档/博客推荐 Docusaurus 或 Pandoc（后者转换能力最强）。
- 学术或需要丰富元数据/脚注时，MultiMarkdown 或 Pandoc 更合适。


> 这个结论基本上符合我的判断，用 DFM 写blog是真舒服，但是GFM更通用但是可用性、易用性一般。但是也没必要为了更通用就去用GFM，写东西最重要的还是 写起来爽、看起来爽，那么我还是选择用 Docusaurus


### 目前最主流的 Markdown flavor 是哪个?

***目前 最主流的 Markdown flavor 是 GFM***

GFM 是 CommonMark 的严格超集，添加了表格、任务列表、删除线、自动链接等最常用的实用扩展，同时保持了很好的兼容性。
