---
name: tools-eval
role: atom
description: 工具形态决策器——判断某个工具（在线/CLI/自建/补全）对我是否有效、该以什么形态存在，输出 keep/drop/replace + 形态归属
---


## 适用与不适用

**是什么**：对一个候选工具（网页工具、CLI 工具、自建候选、补全生态组件等）做**形态决策**——回答两个问题：①对我有没有用（keep / drop / replace）②该以什么形态存在（网页 / CLI / Alfred·devtools / 自建）。

**不是**：工具本身的评测（那是 `explore`）、同类竞品对比（那是 `vs`）、技术拆解（那是 `brk`）。本 skill 只做"**对我**值不值得 + 放哪"的裁决，不做工具好坏的泛化评价。

## 前置闸门（先答，不满足则不进入评估）

1. **这是"新增候选"还是"复盘已有"？** 复盘已有收藏请先走本轮清理上下文；本 skill 面向**新增前**判断（挡 FOMO 累积）。
2. **我是否真的高频需要它？** 频率 < 一月一次的 → 直接 drop，进不了下一步（godbolt 9/10 也因低频移除书签）。

## 评估流程（四问，按序）

### 1. 现有栈重复吗？

- 查 `data/gh` 是否已有同 topic / 同能力工具（`gh search` / `data-cli check`）
- 已有 → **drop**（并入已有，不占独立位）。Notion 被判 drop 不是不好，是现栈已反它。

### 2. 有 CLI/本地上位替代吗？（CLI 优先，先验可推翻）

- 主动找 CLI：`yq`/`jq`/`openssl`/`git`/`pd` 栈/dotfiles 现有工具
- 找到 → **replace**，给出具体 CLI 命令（diffchecker→`delta`/`difftastic`；json-to-go→`quicktype`；onlinetools→CLI 组合）
- **先验可推翻**：任何结论允许被一手证据纠正（carapace "构建有损"→"版本滞后"、json-to-nix "fromJSON"→"源码字面量"）

### 3. 网页壳层真不可替代吗？（keep 的唯一理由）

只有当**至少一项**成立才算真护城河：
- 可视化/交互（Color 选择器、所见即所得、摄像机）
- 链接共享/URL 即记忆（mermaid.live 编辑链接共享、reference 快捷键网格）
- 品牌/权威数据在对方侧（wolframalpha 广度、ping0 原生 IP/共享/场景）
- 无 CLI 等效的运行时/浏览器环境（设备信息）

### 4. 归属哪个形态？

| 需求数据特性 | 形态 | 理由 |
|------|------|------|
| 格式转换、多行结构化、需要预览 | **CLI**（yq/jq/openssl…）| 无状态、确定性、可管道、AI 可调用 |
| 交互/可视化、无输入 | **网页**（但默认不收藏=FOMO 信号）| 三形态里唯一合理 |
| 生成类/可逆变换、输出单行、无需预览、高频 + CLI 记忆成本高 | **devtools**（Alfred）| `dv uuid` → 剪贴板直达 |
| 都不满足 | **drop** | 低频 FOMO，Google 即达 |

判据修正：进 devtools 看**取用成本差**（CLI 是否短到肌肉记忆），不是看"高频"。`uuidgen` 4 个字符不需要 Alfred；`openssl rand` 长命令才值得。

## 输出契约（结构化裁决）

```
## tools-eval 裁决

### 工具
- 名称 / URL / 类型（网页|CLI|自建|补全）

### 裁决
- verdict: keep | drop | replace | 并入已有topic
- form: 网页 | CLI | devtools | 自建 | 无
- frequency: 高频 | 低频 | 未知（FOMO 信号）
- cli_alternative: <具体命令> 或 无
- moat: <网页护城河> 或 无
- overlap: <data/gh 已存在项> 或 无

### 一句结论
<一句话：为什么 keep/drop/replace，放哪个形态>
```

## 条件式推进（next hint）

| 裁决 | 建议下一步 |
|------|-----------|
| replace → CLI | 装进 dotfiles / Taskfile；需要时包一层 `nu` 或 alias |
| keep → devtools | 进 `cmd/devtools` 的 `toolsIndex`（只收生成类+可逆变换、输出单行）|
| keep → 网页 | 进书签（若高频）或仅记 URL（低频但想得起来）；不默认收藏 |
| drop | 不占书签位，需要时 Google 第一屏 |
| 并入已有 topic | 在 `data/gh` 对应 topic 补 record/score |

## 硬约束（编号，可验证）

1. **必须给出** verdict + form 两个字段，不得只答"有用/没用"。
2. **replace 必须给出具体 CLI 命令**，不得只说"有 CLI 替代"。
3. **keep 必须有护城河依据**，禁止"感觉还不错"作为 keep 理由。
4. **CLI 优先**：未主动搜过 CLI 就下 replace/keep 结论的，判为未完成评估。
5. **drop 优先于 keep**：证据不足时默认 drop，理由写"无证据支持保留"。
6. **先验可推翻**：下结论后若用户给出反证，无条件更新裁决。
