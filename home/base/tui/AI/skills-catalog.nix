{
  # https://github.com/ast-grep/agent-skill
  # https://skills.sh/ast-grep/agent-skill
  ast-grep-agent-skill = {
    input = "ast-grep-agent-skill";
    subdir = "ast-grep/skills";
    skills = [
      "ast-grep"
    ];
  };

  # https://github.com/antfu/skills
  # [2026-04-01] 目前质量最高的vue生态skills，比 https://github.com/onmax/nuxt-skills 好用，所以移除掉后者
  antfu = {
    input = "antfu-skills";
    subdir = "skills";
    skills = [
      "antfu"
      "nuxt"
      # https://skills.sh/antfu/skills/pnpm
      "pnpm"
      # what: https://skills.sh/slidevjs/slidev 也就是这个
      "slidev"
      "tsdown"
      "turborepo"
      "unocss"
      "vite"
      "vitepress"
      "vitest"
      "vue-best-practices"
      "vue-router-best-practices"
      "vue-testing-best-practices"
      "vueuse-functions"
      "web-design-guidelines"
    ];
  };

  # https://github.com/anthropics/skills
  anthropic = {
    input = "anthropic-skills";
    subdir = "skills";
    skills = [
      # what: algorithmic art / generative art
      # why: 适合用 p5.js 做 generative art，会先产出算法哲学，再落成 html + js 作品
      # note: 强调原创的 computational aesthetics，不是模仿现成艺术家的静态风格；输出通常会包含 `.md`、`.html`、`.js`
      # htu:
      # - [algorithmic-art] 用 $algorithmic-art 帮我做一个基于 <concept> 的 generative art 作品
      # - [p5js] 用 $algorithmic-art 用 p5.js 做一个可交互的 flow fields / particles / noise sketch
      # - [seeded] 用 $algorithmic-art 做一个带 seeded randomness、可调参数的算法艺术实验
      "algorithmic-art"
      # what: 文档共创 workflow
      # why: 适合协作写文档、proposal、spec、decision doc，会按 Context Gathering -> Refinement -> Reader Testing 三阶段推进
      # note: 它不是“直接替你写完”的 prompt，而是文档共创 workflow；适合中大型文档，不适合一段简单说明
      # htu:
      # - [doc] 用 $doc-coauthoring 帮我一起写这份文档
      # - [spec] 用 $doc-coauthoring 带我起草这份 technical spec / decision doc
      # - [proposal] 用 $doc-coauthoring 按共创 workflow 来整理这份 proposal，不要直接自由发挥
      "doc-coauthoring"
      # what: 高质量 frontend 设计与实现
      # why: 适合直接生成高质量 web UI / page / component / artifact，强调 production-grade、强风格和避免 AI slop
      # note: 是这组技能里的前端总入口；当任务是做页面、组件、落地视觉方向时，通常优先用它
      # htu:
      # - [frontend] 用 $frontend-design 帮我做这个页面 / 组件，要求有明确设计方向
      # - [landing-page] 用 $frontend-design 做一个有强风格的 landing page，不要 generic AI aesthetics
      # - [artifact] 用 $frontend-design 做一个可直接展示的 HTML / React artifact
      "frontend-design"
      # what: 内部沟通写作
      # why: 适合写内部沟通材料，比如 status report、leadership update、3P、incident report、FAQ
      # note: 会根据沟通类型去套对应格式和示例；重点是 internal communication，不是一般 public-facing writing
      # htu:
      # - [internal-comms] 用 $internal-comms 帮我写这份内部沟通稿
      # - [3p] 用 $internal-comms 写一个 3P update
      # - [status-report] 用 $internal-comms 整理这次项目状态更新 / incident report
      "internal-comms"

      # what: skill 创建、评测与迭代
      # why: 适合从 0 创建 skill、改造 skill、做 eval、benchmark 和 description 优化，强调迭代验证而不是一次写完
      # note: 比 `skill-forge` 更偏“创建 + 测试 + 迭代 + description 优化”的全流程；适合需要跑 eval 的场景
      # htu:
      # - [skill] 用 $skill-creator 帮我创建一个新 skill
      # - [eval] 用 $skill-creator 帮我评测并迭代这个 skill
      # - [description] 用 $skill-creator 优化这个 skill 的 description，让 trigger 更准确
      "skill-creator"
      # what: 主题工厂 / artifact 主题应用
      # why: 适合给 slide deck、docs、HTML 页面等 artifact 套一个现成主题，或在现有主题基础上生成新 theme
      # note: 更偏“统一视觉主题应用”，不是从零做设计；它依赖 theme showcase / themes 目录里的预设主题
      # htu:
      # - [theme] 用 $theme-factory 给这个 artifact 套一个主题
      # - [theme-showcase] 用 $theme-factory 先展示可选主题，再让我选
      # - [custom-theme] 用 $theme-factory 根据这个 brief 生成一个新 theme，再应用到 artifact 上
      # "theme-factory"

      # what: 复杂 web artifact 构建工具链
      # why: 适合做复杂的 claude.ai HTML artifact，支持 React + TypeScript + Tailwind + shadcn/ui，并最终 bundle 成单文件 HTML
      # note: 只适合复杂 artifact；简单单文件 HTML/JSX 不需要走这套。它更像 artifact 脚手架 + bundling workflow
      # htu:
      # - [web-artifact] 用 $web-artifacts-builder 帮我做一个复杂的 web artifact
      # - [react-artifact] 用 $web-artifacts-builder 初始化一个 React artifact，并最终打包成单 HTML
      # - [shadcn] 用 $web-artifacts-builder 做一个带 state/routing/shadcn 组件的 artifact
      "web-artifacts-builder"

      # what: 本地 web app 测试 toolkit
      # why: 适合用 Playwright 测试本地 web app，覆盖服务器启动、页面探测、交互验证、截图和日志采集
      # note: 核心是“先探测再操作”；对于动态应用，需要等 `networkidle` 再识别 DOM 和 selector
      # htu:
      # - [webapp-testing] 用 $webapp-testing 帮我测试这个本地 web app
      # - [playwright] 用 $webapp-testing 写一个 Playwright 脚本验证这个页面流程
      # - [with-server] 用 $webapp-testing 配合 `with_server.py` 启动服务并跑自动化测试
      "webapp-testing"
    ];
  };

  # https://skills.sh/wshobson/agents
  wshobson-agents = {
    input = "wshobson-agents";
    subdir = "plugins/kubernetes-operations/skills";
    skills = [
      "helm-chart-scaffolding"
    ];
  };

  # https://skills.sh/hashicorp/agent-skills
  hashicorp-agent-skills = {
    input = "hashicorp-agent-skills";
    subdir = "terraform/code-generation/skills";
    skills = [
      "terraform-style-guide"
      "terraform-test"
    ];
  };

  # https://skills.sh/cxuu/golang-skills
  cxuu-golang-skills = {
    input = "cxuu-golang-skills";
    subdir = "skills";
    skills = [
      # what: Go 专用 code review checklist
      # why: 适合 review 当前 Go 改动，会系统检查格式、文档、错误处理、命名、并发、接口、性能等问题
      # note: 比通用 review skill 更贴近 Go 社区约定；适合 review diff，也适合提交 Go PR 前先做自检
      # htu:
      # - [review] 用 $go-code-review review 当前 Go 改动，按 must-fix / should-fix / nit 输出
      # - [scope] 用 $go-code-review 只看这个 Go 模块/这几个文件的改动
      # - [pre-pr] 用 $go-code-review 先帮我检查这次 Go PR 有没有明显问题，再决定要不要提交
      "go-code-review"
      # what: Go linting / golangci-lint 配置与基线
      # why: 适合新项目建立 `.golangci.yml`，或为现有 Go 项目整理 lint 规则、接 CI
      # note: 偏“代码质量基础设施”，不是 code review 本身；核心是 lint consistently across a codebase
      # htu:
      # - [linting] 用 $go-linting 帮我给这个 Go 项目建立 lint baseline
      # - [golangci-lint] 用 $go-linting 生成或整理 `.golangci.yml`
      # - [CI] 用 $go-linting 把 Go lint checks 接到 CI/CD 里
      "go-linting"
      # what: Go test best practices
      # why: 适合写或重构 Go 测试，重点覆盖 table-driven tests、subtests、cmp.Diff、test helpers 和测试报错可读性
      # note: 更偏“测试写法和结构”，不负责 benchmark；写完测试后一般还要真的跑 `go test`
      # htu:
      # - [test] 用 $go-testing 帮我给这个 Go 函数写测试
      # - [table-driven] 用 $go-testing 把这组 Go 测试整理成 table-driven tests
      # - [subtests] 用 $go-testing 重构这批 Go 测试，加入 subtests / t.Helper / t.Cleanup
      "go-testing"
      # what: Go 文档注释规范
      # why: 适合给 package、type、func、method 补 doc comments，或 review exported symbols 的文档是否到位
      # note: 偏导出符号和 package documentation；不是一般行内注释风格指南
      # htu:
      # - [doc-comments] 用 $go-documentation 帮我给这些 exported Go symbols 补 doc comments
      # - [package-comment] 用 $go-documentation 检查这个 package comment / doc.go 是否规范
      # - [exported] 用 $go-documentation 只看 exported types/functions 的文档缺口
      "go-documentation"
      # what: Go 命名规范
      # why: 适合命名 package、type、func、method、const、receiver，重点看 MixedCaps、initialisms、getter 命名和包名语义
      # note: 很适合 API 设计和重命名场景；与 go-packages / go-functions 有边界但经常一起用
      # htu:
      # - [naming] 用 $go-naming 帮我给这些 Go 标识符重新命名
      # - [package-name] 用 $go-naming 看这个 package 名/receiver 名是否 idiomatic
      # - [initialism] 用 $go-naming 检查 URL/ID/HTTP 这类 initialism 的命名是否一致
      "go-naming"
      # what: Go 并发模式与线程安全
      # why: 适合写 goroutines、channels、mutexes，或排查 data race、goroutine leak、共享状态保护问题
      # note: 核心关注 goroutine lifetime、同步边界和 channel/mutex 取舍；`context.Context` 本身由 go-context 负责
      # htu:
      # - [concurrency] 用 $go-concurrency 帮我 review 这段 Go 并发代码
      # - [goroutine] 用 $go-concurrency 看这几个 goroutine 会不会泄漏，退出机制是否清楚
      # - [race] 用 $go-concurrency 检查这里有没有 data race / 锁粒度 / channel 使用问题
      "go-concurrency"
      # what: Go 性能优化模式
      # why: 适合处理 hot path、benchmark、字符串转换、容量预分配和热点函数优化
      # note: 前提是代码真的在慢，或已经定位到热点；不是默认对所有 Go 代码都做“性能优化”
      # htu:
      # - [performance] 用 $go-performance 看这段 Go 代码慢在哪里
      # - [benchmark] 用 $go-performance 帮我给这个热点写 benchmark / 对比优化前后
      # - [hot-path] 用 $go-performance 只针对 hot path 提建议，不要做泛化优化
      "go-performance"
      # what: Go 错误处理策略
      # why: 适合设计 error wrapping、errors.Is/As、sentinel vs typed errors、log-or-return 和错误边界
      # note: 偏错误语义和传播策略；panic/recover 属于 go-defensive
      # htu:
      # - [errors] 用 $go-error-handling 帮我设计这里的 Go error strategy
      # - [wrapping] 用 $go-error-handling 看这里该用 `%w` 还是 `%v`
      # - [is-as] 用 $go-error-handling 判断这里该不该让调用方用 errors.Is / errors.As 匹配
      "go-error-handling"
      # what: Go 核心风格原则
      # why: 适合处理没有被更专项 skill 覆盖的 Go style 问题，比如 clarity、simplicity、reduce nesting、naked returns
      # note: 更像 Go style fallback；遇到命名、错误、测试、接口等专项问题时，优先用对应专项 skill
      "go-style-core"
      # what: Go 接口与组合设计
      # why: 适合定义或实现 interface，判断何时 accept interfaces / return concrete types，以及抽象边界怎么放
      # note: 这是 Go API 设计里很高频的一块，但更偏抽象设计，不像 testing / linting 那样适合固定 htu 模板
      "go-interfaces"
      # what: Go `context.Context` 使用规范
      # why: 适合设计 context 在函数签名里的位置、取消/超时传播、context value 边界和 request-scoped data 传递
      # note: 只处理 context 语义，不处理 goroutine 生命周期和 sync primitives
      # htu:
      # - [context] 用 $go-context 看这里的 `context.Context` 用法对不对
      # - [timeout] 用 $go-context 帮我设计这里的 timeout / cancel 传播
      # - [context-value] 用 $go-context 判断这个数据该放参数里还是放到 context value 里
      "go-context"
      # what: Go defensive programming patterns
      # why: 适合在 API boundary 上加防御性处理，比如 slice/map copying、cleanup、time 类型、crypto rand、避免 mutable globals
      # note: 偏 robustness hardening；与 go-error-handling、go-interfaces 有交叉，但重点是边界安全和防御性习惯
      "go-defensive"
      # what: Go 数据结构使用模式
      # why: 适合选择 slice/map/array，处理 append、capacity、set 模式、边界复制和 nil vs empty slice
      # note: 很适合容器选型和 collection 处理；并发安全问题还是归 go-concurrency
      "go-data-structures"
      # what: Go 控制流模式
      # why: 适合写 if-init、guard clauses、for/range、switch/type switch，以及识别 shadowing 和 blank identifier 的坑
      # note: 偏语法和结构层面的控制流习惯；错误传播策略还是应该交给 go-error-handling
      "go-control-flow"
      # what: Go functional options pattern
      # why: 适合 public constructor / factory 有很多 optional config 时，设计 `Option` 接口和 `With*` API
      # note: 是非常专项的模式；只有在 constructor 参数开始膨胀、API 需要 extensible 时才值得显式启用
      "go-functional-options"
      # what: Go package 组织与 imports 约定
      # why: 适合拆分 package、组织 imports、处理 `init()`、main/run 模式，以及避免 util/common 这类模糊包名
      # note: 更偏 repo/package 结构设计；与 go-naming 搭配使用效果更好
      # htu:
      # - [packages] 用 $go-packages 帮我设计这个 Go 项目的 package 拆分
      # - [imports] 用 $go-packages 看这组 imports / blank import / dot import 是否合理
      # - [package-size] 用 $go-packages 判断这个 package 是该继续长大，还是该拆
      "go-packages"
      # what: Go 声明与初始化习惯
      # why: 适合处理 `var` vs `:=`、scope 收缩、const/iota、struct literal、零值语义和 `any`
      # note: 偏声明层面的细节规范，通常是 code review 时顺手一起检查，而不是单独高频调用
      "go-declarations"
      # what: Go structured logging 规范
      # why: 适合在 Go 里选 logging 方案、使用 `log/slog`、设计 log levels、request-scoped logging 和字段命名
      # note: 更像生产日志设计指南；与 error-handling 关系紧密，但关注点是 operator-facing logs
      "go-logging"
      # what: Go function design 约定
      # why: 适合整理函数在文件中的排序、函数签名换行、返回值设计、Printf 风格命名和 pointer-to-interface 避免
      # note: 比较偏函数层面的组织和 API 可读性；functional options 另有专项 skill
      "go-functions"
      # what: Go generics 与 type parameters
      # why: 适合判断要不要用 generics、如何设计 constraints，以及什么时候 concrete types / interfaces 更合适
      # note: 核心不是“尽量泛型化”，而是避免 premature generics；只有多个类型共享同一逻辑时才值得启用
      "go-generics"
    ];
  };

  # https://github.com/sanyuan0704/sanyuan-skills
  # https://x.com/GitHub_Daily/status/2020346913690906774
  sanyuan-skills = {
    input = "sanyuan-skills";
    subdir = "skills";
    skills = [
      # what: 高级 code review workflow
      # why: 适合审查当前 git diff，重点看 SOLID、架构异味、安全风险、性能和边界条件
      # note: 更像通用 senior review 模板，适合作为增强型 review 能力；不替代 Go/Vue/Nix 这类领域专用 skill
      # htu:
      # - [basic] 用 $code-review-expert review 当前 git diff，重点看 SOLID、架构边界、安全风险和性能问题
      # - [strict] 用 $code-review-expert 做一次严格 review，按 P0-P3 输出；适合中大型 diff 或准备合并前做体检
      # - [review-only] 如果只想拿审查意见，不想直接改代码，可以明确写“只 review，不要实现修复”
      # - [with-fix] 如果 review 完后希望它继续修，可以在下一轮明确说“按上面的 review 结果修掉 P0/P1”或“修第 2、4 条”
      # - [scope] 如果 diff 很大，可以明确限定范围，比如“只 review auth 模块”或“只看这几个文件的改动”
      # - [fallback] 适合在没有更强领域 skill 时兜底；如果是 Go/Vue/Nix 这类常用栈，最好和领域专用 skill 配合使用
      "code-review-expert"

      # what: 1 对 1 tutor / mastery learning skill
      # why: 通过 Socratic questioning + mastery gate 来系统学习某个主题，会拆 roadmap 并按理解程度推进
      # note: 适合“系统学习某个知识点”，不适合日常 coding workflow；会写入本地学习状态文件
      # htu:
      # - [basic] 用 $sigma 带我学习 <topic>，全程中文；如果不想 lecture，可以明确写“不要直接给答案，先诊断我的水平”
      # - [level] 用 $sigma 教我 <topic>，按 beginner/intermediate/advanced 节奏来，不要默认从最基础开始
      # - [small-topic] 用 $sigma 只带我搞懂 <small topic>，不要扩展太多；适合只啃一个卡点
      # - [resume] 用 $sigma 继续上次的 <topic>，resume 当前 session；sigma 会去读 `sigma/{topic}/session.md`
      # - [restart] 用 $sigma 重新从头教我 <topic>，不要沿用之前的 session；适合同主题但想重开
      # - [diagnose] 用 $sigma 先诊断我对 <topic> 的理解，不要正式进入完整教学流程；适合先摸底
      # - [stop/pause] 在不想继续答题时，直接 stop/pause，sigma 就会自动保存当前状态到 session.md，并生成当前的 summary.html
      # - [switch-mode] 如果不想继续 tutor 模式，可以直接说“停止 $sigma，直接讲解/直接告诉我答案和原因”
      # - [summary] 如果暂时不想继续答题，但也不想完全停掉，可以说“用 $sigma 先总结我已经掌握了什么、还卡在哪里”
      "sigma"
      # what: 写 skill 的 meta-skill / best practices
      # why: 用来设计或优化自定义 skill，包括 description、workflow、references、scripts、assets 和 packaging
      # note: 对当前手搓 skill、整理 catalog、优化 SKILL.md 很有参考价值；与 skill-sk / writing-skills 有重叠，但可作为第三方高质量参考系
      # htu:
      # - [basic] 用 $skill-forge 帮我设计一个新 skill；适合从 0 到 1 梳理 trigger、description、workflow 和目录结构
      # - [rewrite] 用 $skill-forge 重写这个 SKILL.md，让 trigger 更清晰、workflow 更稳定、token 成本更低
      # - [refactor] 用 $skill-forge 帮我把这个 skill 拆成 `SKILL.md` + `references/` + `scripts/` + `assets/`
      # - [review] 用 $skill-forge review 我这个自定义 skill，重点看 description、checklist、confirmation gate、anti-pattern 是否到位
      # - [packaging] 用 $skill-forge 帮我补齐 init / validate / package 所需结构；适合把“能用的 prompt”整理成“可复用的 skill”
      # - [best-practice] 适合拿来优化自己手搓的 skill；它更像第三方高质量参考系，不一定完全照搬，但很适合对照检查
      "skill-forge"
    ];
  };

  # https://x.com/vikingmute/status/2036043855594975485
  # https://github.com/obra/superpowers
  #  - 需求不清/做功能/要方案 -> brainstorming
  #  - 要拆计划 -> writing-plans
  #  - 开始实现 -> executing-plans
  #  - 并行子任务 -> subagent-driven-development 或 dispatching-parallel-agents
  #  - 写代码或修 bug 前 -> test-driven-development
  #  - 遇到异常/测试失败 -> systematic-debugging
  #  - 完成一个任务 -> requesting-code-review
  #  - 收到 review -> receiving-code-review
  #  - 准备宣称完成 -> verification-before-completion
  #  - 准备合并或结束分支 -> finishing-a-development-branch
  obra-superpowers = {
    input = "obra-superpowers";
    subdir = "skills";
    skills = [
      "brainstorming"
      "dispatching-parallel-agents"
      "executing-plans"
      "finishing-a-development-branch"
      "receiving-code-review"
      "requesting-code-review"
      "subagent-driven-development"
      "systematic-debugging"
      "test-driven-development"
      "using-git-worktrees"
      "using-superpowers"
      "verification-before-completion"
      "writing-plans"
      "writing-skills"
    ];
  };
}
