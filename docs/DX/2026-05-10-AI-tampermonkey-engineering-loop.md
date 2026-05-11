---
title: AI时代的油猴脚本自动化开发闭环
date: 2026-05-10
isOriginal: false
---



:::tip[TLDR]

本文的核心在于“油猴脚本自动化开发闭环”，两个关键字：自动化、开发闭环，具体场景则是“油猴脚本”

为啥要做“自动化开发闭环”是不证自明的，尤其在AI时代，直接一个 `/loop` 让AI直接需要的油猴脚本不爽吗？

传统油猴脚本开发通常是“写代码 -> 复制到 Tampermonkey -> 手工点页面验证”。这种方式在简单场景能工作，但在复杂场景会出现两个问题：

- 第一，验证过程不可复现
- 第二，失败后很难让 AI 根据稳定证据继续修复。

本文就这次 `flomo-cleaner` 的目标不是只做一个可运行脚本，而是把整个链路工程化：开发、构建、同步、验证、修复、回归都落到命令和测试上。这样脚本升级不再依赖“手感”，而依赖可执行的验证闭环。

---

最终的效果具体去看 [flomo-cleaner/README.md](../../.tms/packages/flomo-cleaner/README.md)

:::







## ***目前的设计综合说明***


当前设计把能力拆成三层：


1. userscript 工程层：`vite-plugin-monkey` + TypeScript + pnpm monorepo。
2. 用户入口层：Tampermonkey 菜单命令触发脚本。
3. 自动化验证层：Playwright 调用页面 hook，执行 probe/run，并在 reload 后验证真实状态。


核心原则是“用户入口和自动化入口分离”。用户在 Tampermonkey 菜单里点运行；E2E 通过 `unsafeWindow.__flomoCleaner` 触发同一套逻辑，避免测试依赖扩展 popup 的不稳定 UI 交互。



## Tampermonkey：最终用户入口，而不是临时 console script

这个方案里，Tampermonkey 仍然是最终交付形态。脚本通过 `GM_registerMenuCommand` 暴露菜单命令，符合用户日常使用习惯，也避免页面常驻调试按钮污染 UI。

相比 console script，Tampermonkey 的价值在于可安装、可更新、可版本化分发。但对于复杂 destructive UI 自动化，Tampermonkey 沙箱并不会天然提升稳定性，因此验证层仍需独立建设。



### 为什么用户入口用 `GM_registerMenuCommand`

菜单入口更符合用户心智，也能保持页面干净。相比页面浮动按钮，菜单入口是更稳定的最终交付接口。

### 为什么 E2E 入口用 `unsafeWindow.__flomoCleaner`

测试入口必须稳定、可直接调用、可返回结构化结果。`unsafeWindow` hook 能让 Playwright 在页面里直接触发 `probe/run`，并读取可断言的执行结果。

### 为什么不是 Chrome MCP 手点 Tampermonkey popup

扩展 popup 自动化高度依赖 UI 细节，稳定性和可复用性差，不适合作为回归门禁。我们需要的是脚本级可复跑资产，而不是一次性手工操作编排。





### Tampermonkey 菜单 + window hook：手动入口和自动化入口分离

这是一条核心架构线：
- 手动入口：`GM_registerMenuCommand`，给人用。
- 自动化入口：`unsafeWindow.__flomoCleaner`，给测试用。

两者调用同一套 run/probe 逻辑，避免“人工路径”和“测试路径”出现实现分叉。这样才能保证测试通过与真实使用一致。








### 自动更新方案评估（`@downloadURL` / `@updateURL`）

在 userscript 体系里，`@downloadURL` / `@updateURL` 是实现自动更新的标准机制。工程上可行路径是：CI 构建 `.user.js/.meta.js`，再把产物发布到固定 URL，Tampermonkey 按元信息自动拉取更新。

这个方向已经评估过两种落地：

#### 方案A：发布到 Gist

优点是 URL 固定、和代码仓库主分支解耦。
问题是 CI 配置与凭证管理相对繁琐（Gist token / gist id / owner），对当前单脚本维护场景有过度工程化倾向。

#### 方案B：发布到仓库专用分支（例如 `userscripts`）

优点是维护面更小，直接复用仓库与 GitHub Actions 能力，通常比 Gist 更简洁。
问题是仍需引入一条“构建产物分支”的长期维护流程；当前仓库尚未建立该专用分支策略。

#### 当前决策：暂不启用自动更新发布链路

当前只维护 `flomo-cleaner` 一个脚本，手动构建和手动更新 Tampermonkey 的成本可接受。
因此这版暂不引入 `@downloadURL/@updateURL` 的 CI 持久化发布，避免在收益有限阶段增加维护复杂度。

后续当脚本数量增加或发布频率显著上升时，再优先落地“专用分支发布”方案。






## vite-plugin-monkey：把 userscript 变成 Vite 工程

:::tip

`vite-plugin-monkey` 能解决工程化问题，不能改变 Tampermonkey 的运行时本质。

:::

### 它解决工程化，不解决 Tampermonkey 沙箱本质

它提供了 userscript 元信息管理、构建输出、TypeScript 开发体验和包管理集成，让脚本不再是单文件手工维护模式。这是“开发效率和维护性”的提升。

但它不负责解决页面框架的事件链敏感问题，也不会消除 Tampermonkey 与页面上下文的差异。这类问题需要在脚本设计和验证策略里单独处理。

### 页面原生上下文问题仍然需要 page-context injection

`flomo-cleaner` 采用“注入页面上下文脚本执行”的方式，避免把复杂交互完全留在 userscript 沙箱里。特别是下拉菜单、批量选择、删除确认这种敏感交互，必须贴近页面真实事件链。

这也是为什么我们把自动化入口设计成页面可访问 hook：测试直接验证页面侧行为，而不是只验证 Tampermonkey 壳层是否加载。

### 对复杂 destructive UI automation，要额外保守

对“清空列表”这类 destructive 操作，必须把风险控制前置：显式确认、显式环境开关、显式结果验证。不能依赖一次点击后短时间 DOM 变化就判定成功。

本 case 的保守策略是：destructive 测试单独命令、单独开关、执行后 reload 再做最终断言。





### pnpm monorepo：多个油猴脚本按 package 管理

采用 `.tms` workspace + `packages/*` 模式，而不是把所有脚本塞进单项目多入口。这样每个脚本都可以独立维护 `@match`、`@grant`、版本与测试，后续扩展多个 userscript 不会互相耦合。

这个决策的代价是初期目录和命令略复杂，但长期回报是可维护性和可扩展性显著提升。






## Playwright：确定性 E2E 验证层


:::caution

这里要注意为啥使用 `playwright` 而非其他工具

具体查看 [](../LLM/)

:::


Playwright 在这里是“确定性验证层”，不是用户入口层。它负责把脚本行为变成可复跑、可断言、可回归的测试资产，并输出 trace/screenshot 作为失败证据。

关键点是我们不再通过 Playwright 去手点 Tampermonkey popup，而是直接调用 `window.__flomoCleaner`。这样可以保留真实浏览器页面验证，又避免扩展 UI 自动化的高波动性。



### ***为什么 Playwright 要项目内安装，而不是全局 CLI***

:::tip[TLDR]

其他大部分类似工具都直接全局安装，为啥 Playwright 却不推荐安装全局cli以及MCP，而是直接在项目里安装并配置 Playwright呢？

***因为 Playwright 的核心在于 脚本可复用，天生就是基于项目的，而非 `CDP` 或者其他 `web-access Tools`其实都只是临时使用的一次性工具。所以没必要做成什么全局cli，因此也不需要MCP（因为MCP需要全局cli才可用）***

:::



本项目使用 `devDependencies: @playwright/test`，由 `pnpm` 锁定版本。这样可以保证本地、CI、协作者运行的是同一套 Playwright API 和行为。

```ts
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 60_000,
  retries: 0,
  reporter: [["list"], ["html"]],
  use: {
    channel: "chrome",
    headless: false,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },
});

```


全局 CLI 只适合临时实验，不适合作为工程主链路。工程化闭环需要“依赖跟仓库走”，而不是“依赖跟机器走”。




### ***为什么默认使用 headed（`headless: false`）***

:::tip

这里涉及到两个问题：

- 1、总是在用 AI 调用 Playwright 调试部分代码，怎么能让他直接后台运行，不要干扰前台正常工作？
- 2、以及这里为什么仍然需要设置为 `headed` 而非 `headless`？

:::


第一个问题，无非两种

如果 playwright MCP，则配置为

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--headless"]
    }
  }
}
```

如果是 `playwright.config.ts`，则直接配置 headless参数即可

```ts
export default defineConfig({
  use: {
    headless: true,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});
```



---

第二个问题则很简单，在开发阶段最好还是设置为 headed，这样更容易排查，是必须要接受的（比如说我在这个case里，就发现AI一直想通过 listen console output 来判断是否 clean执行完成，但是这个是不合理的，更合理的判断仍然是传统的 `sleep`以及 util页面元素出现 即可），在 生产阶段/测试阶段 则配置为 headless 更合理（避免干扰）。






---


这个 case 的主验收链路是“真实 Chrome + 真实 Tampermonkey 扩展 + 真实持久化登录态”，不是纯无头 smoke。为了减少扩展注入和状态复用的不确定性，当前默认采用 `headless: false` 作为稳定基线。

后台运行不是不能做，而是定位为辅助链路。适合新增一条非破坏性的 headless smoke，用于日常快速检查；但最终验收仍以 headed 链路为准。





### 为什么要 reload 后验证真实状态

只看“操作后瞬时 DOM”容易出现假阳性。`flomo` 有同步与重渲染流程，必须 reload 后再断言 `.memo` 与目标 memo 状态，才是可信验证。

### 为什么 destructive test 必须显式开关

删除链路有真实数据风险，必须要求显式环境变量开启，默认不跑。这样可以在 CI 或本地日常验证中避免误触 destructive 行为。

## E2E Orchestration（Taskfile + setup script）

### 为什么要独立 `setup:flomo-profile`

脚本同步和登录态准备是 E2E 前置条件，独立任务可把“环境准备”从“测试执行”中解耦。失败时能快速定位是脚本问题还是环境问题。

### ***为什么不持久化账号密码到仓库***

```yaml
- 脚本支持自动登录，但只从进程环境变量读取（FLOMO_EMAIL / FLOMO_PASSWORD）。
- 不会把账号密码写进仓库文件或测试代码。
- 所以换机器/新会话时，如果登录态失效，需要你再提供环境变量，或者手动登录一次让profile 复用。
```


`flomo` 账号密码不会写入仓库文件、测试代码或 Taskfile。自动登录只支持进程级环境变量（`FLOMO_EMAIL` / `FLOMO_PASSWORD`）注入，或者人工登录后复用持久化 profile。

这条策略是安全与可维护性的平衡：避免凭证泄漏到 Git 历史，也避免“脚本可跑但秘密管理不可控”。代价是登录态过期后需要重新注入环境变量或手动登录一次。

### 为什么要统一 `verify` / `e2e` 命令

统一命令是 AI 自动修复循环的基础。只有命令标准化，AI 才能稳定执行“改动 -> 验证 -> 根据日志修复 -> 回归”的闭环。


## 从开发到验证的实际闭环

### 1. 开发：TypeScript + vite-plugin-monkey

在 `packages/flomo-cleaner` 实现 userscript 逻辑与入口。核心逻辑保持可测试、可注入、可复用，避免把状态机散落到临时脚本片段里。

测试框架依赖也在项目内安装和锁版本（`@playwright/test`），确保脚本开发与验证在同一依赖语义下演进。

### 2. 构建：生成 `.user.js`

通过 `pnpm build` 产出 `dist/flomo-cleaner.user.js`，作为可安装和可同步的标准产物。

### 3. 同步：自动写入 Tampermonkey

通过 `setup:flomo-profile` 在持久化 Chrome profile 内完成脚本同步，避免手工复制代码到扩展编辑器。

### 4. 验证：Playwright 打开真实 Flomo 页面

先跑非破坏性 probe，再在显式开关下跑 destructive run。验证不仅看执行结果，还要检查刷新后的真实页面状态。

### 5. 修复：AI 根据失败日志继续改

失败后以 Playwright 输出、页面报错和脚本状态为证据修复，不靠猜测。修复后必须回归相同命令链路。

### 6. 发布：以 verify 结果作为交付边界

交付标准不是“代码写完”，而是 `verify` 与 E2E 命令通过。只有验证通过，才进入发布或后续迭代。

## 结论：AI时代的脚本开发标准

对油猴脚本来说，“能运行”已经不够，必须升级到“可重复验证、可自动修复、可稳定回归”。

这一版 `flomo-cleaner` 的经验可以抽象成一个标准模板：


:::tip

- 用 `vite-plugin-monkey` 做工程化开发；
- 用 Tampermonkey 菜单做最终用户入口；
- 用 Playwright + 页面 hook 做确定性验证；
- 用任务命令固化开发到发布闭环。

:::

后续新增 userscript 时，直接复用这套模板，比从 console script 临时起步更稳、更快、也更适合 AI 协作开发。
