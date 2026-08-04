---
name: nix-um
role: atom
description: |
  定期巡检本地未纳管配置（Unified Management），产出两档分级清单；可手动触发的周期任务。
  注意：
  - 1、本prompt将持续维护（随着后续实际执行来做持续优化），目前可能无法真正做到真正纳管所有配置文件。
  - 2、暂时不拆分 sub-agent。两点：1、是否可拆？无依赖关系。2、、是否有必要拆？任务本身耗时且有单独执行必要。结论：本prompt执行频率不高，并且拆分出的prompt不需要单独执行，所以暂时不拆分。
---


对本地配置路径做一次 **纳管（Unified Management）差距巡检**：找出「应该被 nix 纳管、但还没被纳管」的**未纳管配置文件**，按两档分级输出清单。**只做判断，不写代码、不改配置。** runtime / state / secret / 已纳管**不在输出中**——它们不是"未纳管配置"，只是过滤依据。

## 触发条件

- 手动触发：`/zzz nix-um`
- 或周期性调度（半年一次性质）：dagu / Linear recurring issue 负责提醒，本 prompt 本身与调度无关，随时可手动跑

## 扫描范围

直接跑 shell 盘点以下目录，列出其中出现的实体（点文件 / 子目录），**软链 → 已纳管（不进候选）**；普通文件/目录 → 候选。

⚠️ **软链候选排除修正**：仅当软链目标在 **nix store**（含 `-home-manager-files`）**或** sops 渲染路径（`~/.config/sops-nix/secrets/rendered/`）时才算已纳管。软链到**非 store 路径**（如 `~/Desktop/dotfiles/...` git 仓库）→ **仍属候选**，因其不受 nix 回滚/收敛控制，本质是"本地文件的管理副本"，不是 nix 纳管。

```bash
find ~ -maxdepth 1 -name '.*' -not -name '.DS_Store' 2>/dev/null   # $HOME 顶层
find ~/.config -maxdepth 1 -mindepth 1 2>/dev/null                  # ~/.config 子目录
find ~/.local/share -maxdepth 1 -mindepth 1 2>/dev/null             # 应用数据（多数 runtime/state）
find ~/.local/state -maxdepth 1 -mindepth 1 2>/dev/null             # 状态
find ~/Library/Application\ Support -maxdepth 1 -mindepth 1 2>/dev/null  # macOS 应用数据
```

候选列表分出后，**对每个候选路径递归检查其内容**（`find <candidate> -type f`），因为混合态目录（部分 store 软链 + 部分真实文件 + 部分 repo 软链）是常见陷阱——目录级 `ls -la` 可能误判全目录为纳管。

候选过多（>20 个 real file / non-store symlink）时：优先检查 P0 风险高发区（secret 目录、双轨文件名、工具配置目录、指向 git repo 的软链），其余跳过待下次；优先检查 secret 高发区（`~/.ssh`、`~/.gnupg`、`~/.aws`、`~/.config/sops`）。

**明确不扫**（写进「不做」边界）：

- `/var/lib/`、`/run/secrets/`（daemon / secret 层，非用户配置源）
- `.cache`、`.npm`、`.cargo`、`.bun`、`.pip` 等可再生的包缓存
- session / history / DB / socket（`~/.claude/history`、`.zsh_history`、`*.sqlite`、`.local/state` 内 runtime 文件）

## 判断标准：纳管 = 声明 + 落盘收敛

对每个候选路径，执行**三查**（硬约束编号）。**每查都给出可直接执行的命令，不得臆测基准值。**

**先确定「当前 HM generation」**（后续查收敛的基准）：

```bash
# 任一已纳管文件（如 ~/.zshrc）的软链 store 路径，就是当前 hm-files
readlink ~/.zshrc
# 例：/nix/store/b76jgk6mdw4...-home-manager-files/.zshrc
# → 该 store 路径含 "-home-manager-files"，即当前 generation 的 hm-files
```

1. **查声明**：是否有对应 nix 模块 / HM option？
   - 先 `ls -la <path>` 看是否已软链（已软链 → 声明必然有，查落盘/收敛即可）
   - 未软链 → 用**文件名 stem** grep，不用完整路径（nix 里路径常拼接）：`grep -r "<stem>" ~/Desktop/dotfiles/home/base/`
   - 也可直接看模块文件是否 `home.file."<路径>"` / `xdg.configFile`

2. **查落盘**：`ls -la <path>` 是否为软链？链尾在哪？
   - `readlink <path>` 看链尾——在 **nix store**（含 `-home-manager-files`）**或** sops 渲染的 store 外路径（`~/.config/sops-nix/secrets/rendered/`、`mkOutOfStoreSymlink`），**都算合法纳管形态**，不误判缺口
   - ⚠️ 链尾在 `~/Desktop/dotfiles/` / `~/Documents/` / 等**非 store 本地路径** → 不算合法纳管形态，应标为**弱收敛或未纳管**（受 git 控制不等于受 nix 控制，nix 无法对其原子回滚/收敛）

3. **查收敛**：候选文件的软链目标是否属于**当前 generation 的 hm-files**？
   - 对软链候选：`readlink <path>` 的 store 片段，与 `readlink ~/.zshrc` 的 store 片段**对比**——一致 → 收敛；不一致（老 hm-files / 非当前 gen）→ 收敛失败
   - 对 sops 渲染候选（store 外普通文件）：`stat -f "%Sm" <path>` mtime 是否**晚于**最近一次 activate（可看 `~/.zshrc` 或 `/nix/var/nix/profiles/system-*` 最新 link 的时间）
   - rclone 案（mtime 停在 7/21 而 activate 在 7/28）就是收敛失败——nix 声明有，但实际磁盘文件不是 gen 重写的

三查全过 → **已在 nix**（不在输出中）。查文件与查收敛各司其职，缺一不可。声明有但不落盘/不收敛 → **弱收敛**（该进 nix 但未收敛 → 标「P0」）。

**判断补充规则：**
- **路径 / 文件名以官方文档为准**，不以模块注释或现有写法的复数/单数为准（`zed keymaps.json` vs `keymap.json` 教训：官方路径是单数）
- **已有模块的双轨优先于新开模块**：遇到「某配置已有 HM option，但存在本地孤儿文件 / 同名双轨」，应先修双轨并入已有模块，而非新建模块
- **secret 一律走 sops**：凡是 key / token / 明文凭证，应走 `sops-nix`（或外部 secret 管道），不因「纳管」而进 nix store 明文
- **双轨文件即使无泄漏也标 P0**：「已有模块的双轨优先于新开模块」意思是：双轨本地孤儿文件比完全未纳管更危险——nix 声明了一个版本，但实际生效的是本地另一个版本，两边的修改互不同步，造成「以为管好了」的时差陷阱。因此，与已纳管文件构成双轨的孤儿文件，即使无泄漏，也标 **P0**（不应新开模块，应消双轨并入已有模块）
- **分类前 peek 文件内容防误判**：P1 初判的普通文件（路径名不含 secret），须 `head <path>` 或 `file <path>` 确认无 key/token/明文凭证后再定级；若含 secret，升 P0 且建议走 sops，不归 P1
- **软链到 git 仓库 ≠ 纳管**：链尾在 `~/Desktop/dotfiles/` 等本地仓库的软链，属手动管理副本，不受 nix 回滚/收敛控制。判断时一律视为弱收敛/未纳管，不因"软链"而跳过。常见于 `.hammerspoon/Spoons/` 等既有 nix 声明又有 git 手动维护的混合态目录。
- **目录级混合态需逐文件判断**：一个目录可能同时包含 store 软链、repo 软链、真实文件三种形态。不得以目录级 `ls -la` 结果代表全部内容；必须递归到文件级检查。

## 反面定义（防越界）

**「纳管」不是什么：**
1. **声明在 nix ≠ 被纳管**：launchd 弱收敛、mutable 副作用文件不算真纳管
2. **home.file ≠ 明文进 store**：`sops.templates` / path 引用 / env 注入都是合法纳管路径，不得误判
3. **双轨文件比「没管」更危险**：同名不同写法（复数/单数）优先标 P0，因其实际生效的文件往往未纳管
4. **runtime/state 不是配置**：history、sqlite、session、db、cache、secret 一律排除，**不输出、不进候选**（不是档位，是过滤依据）

**本 prompt 不做什么：**
5. **不写代码 / 不改配置**：只做判断与分级，改 nix 是后续步骤
6. **不自动拆 issue / 不写回 Linear**：P0 项建议由用户决定是否拆 issue
7. **不做清理**：不输出"该删什么"，不判 runtime 残留——只判断"未纳管配置文件"

## 用户问答边界（防 scope creep）

用户在中途追问某路径「是什么」「怎么判」「怎么处理」，**不是执行指令，是要求判断框架内的分类说明**。回答必须从已有规则推导，不得触发新的现场命令。

### 内联查询处理流程

用户可能在扫描中途或输出后问"这个路径算不算配置？""那个路径怎么处理？"。此时按以下流程回答：

1. **归类**：将路径映射到以下类别之一
   - **runtime / state / history / DB / cache / socket** → 不是配置（引用「明确不扫」和「反面定义 §4」），不进候选、不输出
   - **secret / key / token 明文**（如 `~/.config/sops/age/keys.txt`）→ sops 加密管道的基础设施自身，不是"待纳管配置"；被 sops 加密的配置文件才算候选
   - **已纳管**（软链指向当前 hm-files store）→ 不在输出中
   - **未纳管配置文件**（普通文件，非 runtime/state/secret，且非软链）→ 按三查判断后分入 P0/P1

2. **引用**：引用 skill 中对应规则的原文（如「明确不扫」中的条目、「secret 一律走 sops」、三查标准）作为依据

3. **回答**：一句话给出结论 + 理由。不模棱两可，不推给上一轮输出

**示例：**
> **~/.config/sops/age/keys.txt** → sops 自身密钥文件，属于加密管道基础设施，不是待纳管配置。secret 一律走 sops（引用判断补充规则§3），但 sops 自己的 key 是这条管道的钥匙，不列入候选名单。
> **~/.claude/history.jsonl** → history runtime 文件，引用「明确不扫」§3：`session / history / DB / socket（~/.claude/history…）`，不输出。

### 通用守界规则

- **只分类，不跑命令**：用户问某路径是否算配置 / 该归哪档 → 引用已有规则（反面定义 / 明确不扫 / 三查框架 / 两档定义）回答即可。不再跑 `ls -la` / `readlink` / `stat` / `grep` 等实际命令
- **只归因，不补测试**：答完即止，不得顺带跑命令来「验证」答案
- **只给建议动作模板，不写具体操作步骤**：「建议动作」保持 prompt 示例的抽象粒度（如「消双轨：合并进 xxx.nix」），不展开多步修复步骤或 shell 命令
- **secret 类追问只指明规则，不查现场**：用户问某 secret 路径 → 陈述「secret 一律走 sops，不进 nix store 明文」规则即止，不实际验证该路径是否存在、权限如何、公钥是否匹配

**越界示例（不应出现）：**
- 用户问 `~/.config/sops/age/keys.txt` → 跑命令看文件内容、比公钥、查 mode → **越界**
- 用户问 `~/.claude/history.jsonl` → 读文件、看大小、确认 mtime → **越界**
- 用户问某个 config.toml 是 P0 还是 P1 → 补扫描命令确认它真实存在 → **越界**

**守界示例（应做）：**
- 用户问 `~/.claude/history.jsonl` → 引用「明确不扫」段 → 属于 session/history，不是配置候选。不加新命令
- 用户问某文件属于哪档 → 按两档定义 + 三查框架回答，从已知规则推导，不额外跑命令

## 分级输出（两档 + heading 嵌套，必须使用）

### 模板

各级别用 `##`，级别下的每个 case 用 `###`，case 内用列表字段。**按 P0 → P1 顺序输出**，只有实际出现的级别才输出。runtime / state / secret / 已纳管**不输出**（是过滤依据，不是档位）。

```markdown
# nix-um 巡检结果

## P0

### <路径>
- 现状：<现状描述>
- 判断依据：<三查结果摘要>
- 建议动作：<下一步>

## P1

### <路径>
- 现状：...
- 判断依据：...
- 建议动作：...
```

- **P0（该进且有害）**：该进 nix，且有 泄漏 / 双轨 / 明文，要动，拆 follow-up issue
- **P1（该进但无害）**：该进 nix，纯配置、无泄漏（低风险，该进但不急）


### 示例（参考，非模板）

```markdown
## P0

### ~/.config/zed/keymap copy.json
- 现状：普通文件 3.9K，与已纳管 keymap.json 同名双轨
- 判断依据：声明有（zed.nix 管 keymap.json）落盘否（copy 是孤儿）→ 双轨
- 建议动作：消双轨，merge 进 zed.nix 后删孤儿

## P1

### ~/.config/hunk/config.toml
- 现状：普通文件
- 判断依据：声明否 / 落盘否 → 该进 nix，纯配置无泄漏
- 建议动作：纳入 hunk.nix（低风险，不急）
```


### 字段契约

- **现状**：一句话描述实态（如"普通文件 mode 0600" / "store 软链" / "孤儿文件"）
- **判断依据**：三查结果摘要 + 定性结论（如"声明有 / 落盘否 / 收敛否 → 弱收敛"）
- **建议动作**：对应的下一步（如"消双轨：合并进 zed.nix" / "纳入 xxx.nix"）

### 自检（输出前必过）

- 所有 **P0** 项是否都有**拆 issue 建议**？
- 所有 **P1** 项是否都有**纳管建议**？
- 是否把 runtime/state/secret 当成了该进 nix 候选？（它们不输出，是过滤依据）
- 级别是否只有 P0 / P1 两种？（不出现其它级别）


## 交付

- **只在聊天输出**未纳管配置清单（heading 嵌套：级别 `##` + case `###`，两档）
- 不自动写回任何文件 / Linear；P0 需要的话由用户决定是否拆 issue
- 若本次发现有上一轮判过的项，仍按当前标准独立判断，不默认沿用旧结论
- **可选：已排除摘要**——若巡检中自然遇到大量 runtime/state/secret 项（用户可能因此疑惑的），可在 P0/P1 清单末尾用纯文本节（非 heading 嵌套）简要列出过滤依据，避免疑惑；少量时不额外输出
- **前后扫描 delta 注明**：若上一轮判过的项在本轮中状态变化，应在对应 case 中注明。例如：上一轮 P0 的弱收敛已修复 → 注明「已收敛，不输出」或「已修复，降级」；上一轮项仍存在 → 按当前标准独立判断并在判断依据中提「与上一轮一致」。不默认沿用旧结论，但主动标注前后变化能避免用户疑惑

## Next Action（输出后的条件式推进）

| 条件 | 建议 next |
|------|-----------|
| 有 **P0** 项 | 建议拆 follow-up issue（每项一个），用户点头后执行 |
| 有 **P1** 项 | 可评估是否纳入 nix（用户确认后） |
| 全部为空（无缺口） | 巡检完成，无需后续动作 |
| 用户想深挖某档 | 可对该档再跑一次专项判断 |
