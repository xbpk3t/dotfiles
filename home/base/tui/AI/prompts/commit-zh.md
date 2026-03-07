---
description: Generate a Conventional Commit message from staged diff (with type & scope inference)
argument-hint: [TYPE=<feat|fix|docs|refactor|test|perf|style|chore|build|ci>] [SCOPE=<scope>] [TICKET=<id>] [LANG=<en|zh>] [BODY=<0|1>]
---

你在生成 git commit message（Conventional Commits 风格），并且需要**谨慎选择 type**与**自动推断 scope**。

## 0) 先决条件
1) 运行：git diff --staged
   - 如果没有 staged changes，回复必须严格等于：
     No staged changes. Please run git add first.

## 1) 默认值
- TYPE=feat
- SCOPE=（自动推断；推断失败则回退为 api）
- TICKET=""（空字符串）
- LANG=zh
- BODY=1

> 注意：即使 LANG=zh，也必须保留 TYPE/SCOPE/TICKET 原样（英文/符号不翻译），只把 summary/body 写成中文。

## 2) Commit message 结构（必须遵守）
### 2.1 Subject 行格式
- 有 scope：TYPE(SCOPE): <summary>
- 无 scope：TYPE: <summary>
- 若 TICKET 非空：TYPE(SCOPE): [TICKET] <summary>
- subject 尽量 <= 72 chars（超出时优先缩短 summary）

### 2.2 Summary（subject 的 <summary>）规范
- **动词开头（祈使/陈述均可，但以“动词 + 宾语/目的”风格优先）**
- **开头小写（英文时）**；中文无需大小写，但仍要“动词开头”
- **不加句号/句末标点**（不以 “.” / “。” / “！” / “?” 结尾）
- 避免空泛词：比如 “update”, “change”, “fix stuff”
- 尽量描述“做了什么 + 作用对象”，例如：
  - zh：`修复订单创建时的空指针`
  - en：`handle null order id in create flow`

### 2.3 Body（当 BODY=1）
- subject 后空一行
- 使用最多 4 条 bullet points（以 `- ` 开头）
- bullet points 写清：
  - 改了什么（行为/模块）
  - 为什么（可选）
  - 影响（可选：breaking/兼容性/性能/风险）
- 不要写无意义复述，不要贴大段 diff

## 3) Type 规范与选择（重点：谨慎判断）
### 3.1 预定义类型（推荐集合）
- 代码类：feat, fix, perf, style, refactor
- 非代码类：test, ci, docs, build, chore

### 3.2 type 含义（判定口径）
- feat：新增用户可感知能力/接口/功能路径（包含新增 endpoint/参数/行为）
- fix：修复用户可感知的 bug（运行时行为错误、接口错误、逻辑错误）
- perf：性能提升（更快/更省资源），且不是纯重构
- style：仅格式/空格/分号/排序（不改变逻辑与输出）
- refactor：重构（改变内部结构，不改变外部行为；不修 bug、不加新特性）
- test：新增/修改测试用例或测试基础设施（不影响生产逻辑）
- ci：CI/CD 配置与流水线（如 GitHub Actions、GitLab CI、Jenkins pipeline）
- docs：文档/注释/README/变更日志（不影响代码行为）
- build：构建系统与依赖（打包、编译、工具链、依赖版本、bundle 配置）
- chore：杂项维护（脚本、目录清理、元数据、无明显归类的小改动）

### 3.3 核心决策原则（解决 “build 的 bug” 场景）
**选择 type 先看“问题/变更的本质”，再看“发生的地方”。**
- 如果修的是“用户/运行时行为 bug” → 用 `fix(...)`，即使改动出现在 build 文件里也是 fix
- 如果修的是“构建/打包/依赖/发布流程 bug”（影响编译/安装/CI/产物）→ 用 `build(...)` 或 `ci(...)`
- 如果同时包含两类：优先选对外影响更大的那类；必要时用 body 说明并在 scope 用 `multi` 或最主要模块

#### 3.3.1 判定例子（必须遵守）
- 依赖锁文件修复导致构建失败：`build(deps): ...`
- 修复 CI 脚本导致 pipeline 失败：`ci(pipeline): ...`
- 修复 webpack/vite 配置导致产物无法运行（但问题本质是构建产物错误）：`build(web): ...`
- 修复生产运行时 bug，恰好需要调整构建配置（例如注入 env 导致逻辑修复）：**仍然优先 `fix(...)`**
  - ✅ `fix(auth): ...`（body 里写“同时调整了 build 配置以注入 env”）
  - ❌ `build: fix ...`（不要在 summary 里写“fix”作为动词名词混用）

### 3.4 type 选择快速规则（按优先级）
1) 是否新增能力/路径？是 → feat
2) 是否修复错误行为/缺陷？是 → fix
3) 是否仅提升性能？是 → perf
4) 是否只改格式？是 → style
5) 是否内部结构调整且外部行为不变？是 → refactor
6) 是否仅测试？是 → test
7) 是否仅 CI？是 → ci
8) 是否仅文档？是 → docs
9) 是否构建/依赖/工具链？是 → build
10) 以上都不明显 → chore

## 4) Scope 自动推断（根据 staged diff 生成）
### 4.1 scope 的目标
- scope 应该是**受影响的模块/包/域**，而不是动作
- 取值尽量短、稳定、可搜索（推荐英文小写、kebab-case 或常用模块名）
- 不要把 type 重复进 scope（例如 scope=fix/build）

### 4.2 推断方法（从 diff 中抽取）
当用户未提供 SCOPE 时，你必须尝试推断：
1) 统计被修改文件路径的“最常见上层目录/模块名”
   - 例如：`src/auth/*` → scope=auth
   - `packages/api/*` → scope=api
   - `apps/web/*` → scope=web
2) 若是 monorepo：
   - 优先取 package/app 名（packages/* 或 apps/* 的第二段）
3) 若改动集中在单一功能域文件：
   - 根据文件名/目录推断（如 `router`, `controller`, `service` 的父目录）
4) 若涉及多个明显模块：
   - 选择改动行数/文件数最多的模块
   - 若无法明确主模块，用 `multi`
5) 若只改根目录配置：
   - 构建相关（package.json, lockfile, tsconfig, vite/webpack 等）→ scope=build 或 deps（更细优先 deps）
   - CI 配置（.github/workflows 等）→ scope=ci 或 pipeline
   - 其他通用配置（.editorconfig, .prettierrc, lint）→ scope=tooling 或 lint
6) 推断失败：回退到 `api`

> 约束：scope 不要超过 20 chars（超出则选更短的上层名或用通用名）

## 5) 输出规则（严格）
1) 只输出最终 commit message
2) 不要代码块，不要解释，不要额外前后缀
3) BODY=1 时：subject + 空行 + 1~4 条 bullet points
4) LANG=zh：summary/body 用中文；LANG=en：summary/body 用英文

## 6) 生成内容要求（基于 diff）
- summary：概括本次提交最核心的意图与影响面
- body bullet points：覆盖关键文件/模块变化、行为变化、风险点（如有）

现在开始执行第 0 步并生成 commit message。
