---
frontmatter:
  name: nix-um
  role: atom
  desc: 定期巡检本地未纳管配置（Unified Management），产出 P0/P1 两档分级清单；可手动触发的周期任务
---

## what

**是什么：**

对本地配置路径做一次纳管（Unified Management）差距巡检：找出「应该被 nix 纳管、但还没被纳管」的未纳管配置文件，按两档分级输出清单。
只做判断，不写代码、不改配置。

**不是：**

runtime / state / secret / 已纳管 不在输出中（它们是过滤依据，不是候选）
不写代码 / 不改配置 / 不自动拆 issue / 不做清理

## constraint

### must

1. 路径/文件名以官方文档为准
2. 已有模块双轨优先于新开模块
3. secret 一律走 sops
4. 双轨文件即使无泄漏也标 P0
5. 分类前 peek 文件内容防误判
6. 目录级混合态需逐文件判断
7. 软链到 git 仓库 ≠ 纳管

### must-not

1. 禁止把 runtime/state/secret 当候选
2. 禁止目录级 ls -la 代表全部内容（必须递归到文件级）
3. 禁止不跑命令只臆测基准值

## workflow

### 扫描范围

1. 直接跑 shell 盘点以下目录，列出其中出现的实体（点文件 / 子目录）：软链 → 已纳管（不进候选）；普通文件/目录 → 候选
2. ⚠️ 软链候选排除修正：仅当软链目标在 nix store（含 -home-manager-files）或 sops 渲染路径（~/.config/sops-nix/secrets/rendered/）时才算已纳管。软链到非 store 路径（如 ~/Desktop/dotfiles/... git 仓库）→ 仍属候选（不受 nix 回滚/收敛控制，本质是本地文件的管理副本）
3. 候选列表分出后，对每个候选路径递归检查其内容（find <candidate> -type f），因为混合态目录（部分 store 软链 + 部分真实文件 + 部分 repo 软链）是常见陷阱——目录级 ls -la 可能误判全目录为纳管
4. 候选过多（>20 个 real file / non-store symlink）时：优先检查 P0 风险高发区（secret 目录、双轨文件名、工具配置目录、指向 git repo 的软链），其余跳过待下次；优先检查 secret 高发区（~/.ssh、~/.gnupg、~/.aws、~/.config/sops）
5. 执行以下命令
```bash
find ~ -maxdepth 1 -name '.*' -not -name '.DS_Store' 2>/dev/null   # $HOME 顶层
find ~/.config -maxdepth 1 -mindepth 1 2>/dev/null                  # ~/.config 子目录
find ~/.local/share -maxdepth 1 -mindepth 1 2>/dev/null             # 应用数据（多数 runtime/state）
find ~/.local/state -maxdepth 1 -mindepth 1 2>/dev/null             # 状态
find ~/Library/Application\\ Support -maxdepth 1 -mindepth 1 2>/dev/null  # macOS 应用数据
```

6. 明确不扫：/var/lib/、/run/secrets/（daemon/secret 层）；.cache、.npm、.cargo、.bun、.pip 等可再生包缓存；session/history/DB/socket（~/.claude/history、.zsh_history、*.sqlite、.local/state 内 runtime 文件）

### 判断标准（纳管 = 声明 + 落盘收敛）

**gate:** 候选列表已分出

1. 先确定当前 HM generation（后续查收敛的基准）：readlink ~/.zshrc → /nix/store/...-home-manager-files/.zshrc，该 store 路径即当前 generation 的 hm-files
2. 对每个候选路径执行三查（每查都给出可直接执行的命令，不得臆测基准值）：
1. 查声明：是否有对应 nix 模块 / HM option？
  - 先 ls -la <path> 看是否已软链（已软链 → 声明必然有，查落盘/收敛即可）
  - 未软链 → 用文件名 stem grep（nix 里路径常拼接）：grep -r \"<stem>\" ~/Desktop/dotfiles/home/base/
  - 也可直接看模块文件是否 home.file.\"<路径>\" / xdg.configFile
2. 查落盘：ls -la <path> 是否为软链？链尾在哪？
  - readlink <path> 看链尾——在 nix store（含 -home-manager-files）或 sops 渲染的 store 外路径（~/.config/sops-nix/secrets/rendered/、mkOutOfStoreSymlink）都算合法纳管形态
  - ⚠️ 链尾在 ~/Desktop/dotfiles/ / ~/Documents/ 等非 store 本地路径 → 不算合法纳管形态，标为弱收敛或未纳管
3. 查收敛：候选文件的软链目标是否属于当前 generation 的 hm-files？
  - 对软链候选：readlink <path> 的 store 片段，与 readlink ~/.zshrc 的 store 片段对比——一致 → 收敛；不一致 → 收敛失败
  - 对 sops 渲染候选：stat -f \"%Sm\" <path> mtime 是否晚于最近一次 activate
  - rclone 案（mtime 停在 7/21 而 activate 在 7/28）就是收敛失败

3. 三查全过 → 已在 nix（不在输出中）；声明有但不落盘/不收敛 → 弱收敛 → 标 P0

### 判断补充规则

1. 路径/文件名以官方文档为准，不以模块注释或现有写法的复数/单数为准
2. 已有模块的双轨优先于新开模块（修双轨并入已有模块，而非新建模块）
3. secret 一律走 sops（key/token/明文凭证，不因纳管而进 nix store 明文）
4. 双轨文件即使无泄漏也标 P0（「以为管好了」的时差陷阱）
5. 分类前 peek 文件内容防误判（head/file 确认无 key/token/明文凭证；含 secret 升 P0 走 sops）
6. 软链到 git 仓库 ≠ 纳管（链尾在 dotfiles 等本地仓库的软链视为弱收敛/未纳管）
7. 目录级混合态需逐文件判断（递归到文件级检查）

### 用户问答边界（防 scope creep）

**gate:** 用户在中途追问某路径

1. 归类：runtime/state/history/DB/cache/socket → 不是配置；secret 明文 → sops 管道基础设施本身；已纳管 → 不输出；未纳管配置文件 → 按三查分 P0/P1
2. 引用：引用 skill 中对应规则原文作为依据
3. 回答：一句话结论 + 理由，不模棱两可
4. 守界：只分类不跑命令 / 只归因不补测试 / 只给建议动作模板不写具体操作步骤 / secret 类追问只指明规则不查现场

## output

**format:** md

**struct:**

- key: P0
  val: 该进且有害（泄漏/双轨/明文），要动，拆 follow-up issue
- key: P1
  val: 该进但无害（纯配置、无泄漏），低风险该进但不急

**template:**

```markdown
# nix-um 巡检结果

## P0

### <路径>
- 现状：<一句话实态>
- 判断依据：<三查结果摘要>
- 建议动作：<下一步>

## P1

### <路径>
- 现状：...
- 判断依据：...
- 建议动作：...

# 单条项格式
- 现状：一句话描述实态（普通文件 mode 0600 / store 软链 / 孤儿文件）
- 判断依据：三查结果摘要 + 定性结论（声明有/落盘否/收敛否 → 弱收敛）
- 建议动作：对应的下一步（消双轨：合并进 zed.nix / 纳入 xxx.nix）
```

## self-check

| # | 检查项 |
| --- | --- |
| 1 | 所有 P0 项都有拆 issue 建议？ |
| 2 | 所有 P1 项都有纳管建议？ |
| 3 | 没把 runtime/state/secret 当候选？ |
| 4 | 级别只有 P0/P1 两种？ |
