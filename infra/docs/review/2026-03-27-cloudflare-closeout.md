# Cloudflare 收编收尾说明

这篇文档是这次 `infra/` 内 Cloudflare 收编工作的最终收尾说明。

它主要回答 3 个问题：

1. 这次到底做成了什么
2. 你以后日常应该怎么使用和维护 `infra/`
3. 还有哪些边界项需要知道，但当前不必继续展开

## 1. 本次收编的最终结果

这次 Cloudflare 线已经从“旧 TF + dashboard 手工操作 + 明显 drift”的状态，收束到了现在这套结构：

```text
infra/
  Taskfile.yml
  .task/
    Taskfile.stack.yml
    Taskfile.cf.yml
  inventory/
    <date>/cloudflare/
  cloudflare/
    README.md
    ADOPTION.md
  stacks/
    homelab/
      cloudflare/
        lucc.dev/
          dns/
          email-routing/
        account/
          d1/
          kv/
          pages/
          r2/
```

本次已经完成的核心工作：

- 建立了 Cloudflare inventory 流程
- 把 Cloudflare 正式拆成多个 stack，而不是一个大 state
- 把 Cloudflare stacks 的 remote state 迁到 Cloudflare R2 backend
- 把原本只存在于 dashboard/live 的资源，先 adopt/import 到 state
- 再把确认废弃的资源做第二轮真实删除
- 把日常维护入口收束到 `locals.tf` 的数据模型，而不是手写大量 `resource` block
- 把旧 `.taskfile/devops/Taskfile.tf.yml` 这条维护路径事实上替换为 `infra/Taskfile.yml`

## 2. 当前 stack 边界

当前已经建立的 Cloudflare stack：

- `infra/stacks/homelab/cloudflare/lucc.dev/dns/`
- `infra/stacks/homelab/cloudflare/lucc.dev/email-routing/`
- `infra/stacks/homelab/cloudflare/account/d1/`
- `infra/stacks/homelab/cloudflare/account/kv/`
- `infra/stacks/homelab/cloudflare/account/r2/`
- `infra/stacks/homelab/cloudflare/account/pages/`

这样拆的意义是：

- zone 级资源和 account 级资源分开
- DNS / Email Routing 不和 Pages / D1 / R2 混在一个 state
- 单次 `plan/apply` 的 blast radius 更小
- 后续做 adopt / delete / rollback 更可控

## 3. 日常怎么用 `infra/`

以后日常维护 Cloudflare，不要再回到“直接看 dashboard + 手改旧 TF 文件”的方式。

建议把工作流固定成下面这几类动作。

### 3.1 看有哪些 stack

```bash
task tf
task tf:list
task tf:list TAG=cloudflare
task tf:cf:list
```

用途：

- 快速看当前 `infra/` 里有哪些 stack
- 确认 Cloudflare 相关 stack 路径

### 3.2 拉最新 live inventory

```bash
task tf:inventory
task tf:inventory DATE=2026-03-27
```

用途：

- 从 Cloudflare API 拉当前真实资产快照
- 用来确认 dashboard/live 当前状态
- 适合在“大改之前”或者“怀疑 drift 之后”先跑一次

注意：

- inventory 是只读盘点
- inventory 不会改任何 live 资源
- inventory 的价值是“看清楚当前现实状态”，不是“直接生成最终可维护配置”

### 3.3 校验某个 stack

```bash
task tf:validate STACK=infra/stacks/homelab/cloudflare/lucc.dev/dns
task tf:validate STACK=infra/stacks/homelab/cloudflare/account/pages
```

用途：

- 本地快速确认 HCL 结构没坏
- 不依赖真实 apply

### 3.4 预览某个 stack 的变更

```bash
task tf:plan STACK=infra/stacks/homelab/cloudflare/lucc.dev/dns
task tf:plan STACK=infra/stacks/homelab/cloudflare/account/r2
```

如果只是巡检整组 Cloudflare stacks：

```bash
task tf:plan TAG=cloudflare
task tf:cf:plan
```

用途：

- 日常维护时，先看 drift
- 做任何 live 改动前，先确认计划

### 3.5 真正执行某个 stack 的变更

```bash
task tf:apply STACK=infra/stacks/homelab/cloudflare/lucc.dev/dns
task tf:apply STACK=infra/stacks/homelab/cloudflare/account/d1
```

用途：

- 把本地声明同步到 Cloudflare live

建议：

- 默认只对单个 stack 做 `apply`
- 除非你非常确定，不要把整组 Cloudflare 当成一个“批量 apply 单位”

## 4. 你以后维护时该改哪里

核心原则：

- 日常优先改 `locals.tf`
- 少直接改 `main.tf`
- 除非是 provider/schema 变化，否则不要频繁碰 `imports.tf`

### 4.1 正常新增或修改资源

以 DNS 为例：

- 改 [infra/stacks/homelab/cloudflare/lucc.dev/dns/locals.tf](/Users/luck/Desktop/dotfiles/infra/stacks/homelab/cloudflare/lucc.dev/dns/locals.tf)
- 然后跑：

```bash
task tf:plan STACK=infra/stacks/homelab/cloudflare/lucc.dev/dns
task tf:apply STACK=infra/stacks/homelab/cloudflare/lucc.dev/dns
```

对于 D1 / KV / R2 / Pages 也是同样思路。

### 4.2 如果 dashboard 手工改过了

不要直接猜。

先做：

```bash
task tf:inventory
task tf:plan STACK=...
```

然后判断这次 drift 属于哪一类：

- 只是临时手改，需要回写到 IaC
- 还是本地配置已经过时，需要以 live 为准更新 `locals.tf`

长期目标不是“双向同步”，而是：

- Cloudflare dashboard 只做临时诊断
- `infra/` 成为最终唯一写入面

## 5. 删除资源的正确流程

这一点是这次收编里最容易踩坑的地方。

如果某个资源原本只存在于 Cloudflare live，但从未进入 state，那么：

- 你在本地把它注释掉
- 或者把它从 `locals.tf` 里删掉

都不会触发删除。

原因很简单：

- OpenTofu 只会删除“已经在 state 里、但配置里不再存在”的资源
- 对“从未纳管”的 live 资源，它不会主动碰

所以删除现有 live 资源，必须走两轮：

### 第一轮：先收编

- 先把资源保留在 `locals.tf`
- 跑一次 `plan/apply`
- 让它 import/adopt 进 state

### 第二轮：再删除

- 再把这个条目从 `locals.tf` 里移除
- 再跑一次 `plan/apply`
- 这时才会生成真正的 `destroy`

一句话记忆：

- 第一次 `apply` 是 adopt
- 第二次 `apply` 才是 delete

## 6. Secret 和环境变量怎么理解

当前 Cloudflare 线常用 env：

- `CLOUDFLARE_API_TOKEN`
- `CF_ACCOUNT`
- `CF_ZONE`
- `CF_R2_AK`
- `CF_R2_SK`
- `TF_VAR_pages_docs_cfp_pwd`

说明：

- `CLOUDFLARE_API_TOKEN`
  - provider 读这个
  - 日常 `plan/apply` 默认就用它
- `CF_R2_AK` / `CF_R2_SK`
  - 给 Cloudflare R2 backend 用
  - task 会透明映射成 OpenTofu backend 底层需要的 `AWS_*`
- `TF_VAR_pages_docs_cfp_pwd`
  - 这是 OpenTofu 的变量注入约定
  - 用来把 `pages_docs_cfp_pwd` 传给 Pages stack

这里最重要的实践结论是：

- 日常维护 token 应该直接使用一枚能完成 read/write 的 `CLOUDFLARE_API_TOKEN`
- 如果你还想保留只读 token，可以额外保留一个只读 env 名
- 但不要把默认维护入口绑到只读 token 上

## 7. `pages/nextflux` 的当前状态

`nextflux` 在这次工作里是一个特例。

当前状态：

- 它已经被单独 import 进 Pages stack 的 state
- 这样做的目的，是先把“待删 Pages 项目”收编进 state
- 但我没有把整个 Pages stack 一次性全量 apply 到彻底一致

原因：

- Pages provider 的返回内容较重
- `pages` stack 里有 build config / deployment config / source config / secret 等维度
- 如果在没有把所有 live 配置完全审过一遍之前就硬推全栈 apply，风险会高于 DNS / KV / D1

所以目前对 `nextflux` 的理解应该是：

- 它已经进入“可被 Terraform/OpenTofu 正确处理”的轨道
- 但删除动作要继续坚持“单项确认后再操作”，不要把整个 Pages stack 当作 DNS 那样直接粗推

后续如果你要处理它，建议顺序是：

1. 先只看 `pages` stack 的 plan
2. 单独确认 `nextflux` 是唯一预期删除项
3. 再执行 apply

## 8. R2 那几个 bucket 的状态说明

这次待删的 R2 buckets 主要包括：

- `blog`
- `dokploy-backup`
- `dokploy-volume-backup`
- `rclone`
- `scratches`
- `vps`

当时的实际情况是：

- 第二轮 destroy 已经成功触发
- `blog` 明确删除完成
- 另外几个 bucket 在 Cloudflare 侧进入了长时间 `still destroying`

这类现象通常意味着两种可能：

1. bucket 非空，Cloudflare 需要更长时间处理，或者直接不允许立即删除
2. 后台清理流程本身较慢

因此这里的正确心智模型不是：

- “R2 资源一删就立刻没了”

而是：

- “R2 bucket 删除有更高概率受对象内容和后台清理影响”

所以以后处理 R2 删除时，建议多加一步预检查：

- 先确认 bucket 是否为空
- 如果不为空，先清空对象
- 再做 OpenTofu destroy

## 9. 当前暂不纳管的部分

当前有意暂不继续深挖的部分：

- Workers scripts

原因不是 provider 做不到，而是当前阶段这样做维护性很差：

- script code 会直接内联到 HCL
- bindings / secret / deployment 细节容易一起耦合进 state
- 会把“基础设施收编”和“应用代码发布”混在同一个 Terraform 资源模型里

所以当前策略是：

- Workers 保持在 inventory 可见
- 等后续明确源码仓库、发布链路、secret ownership
- 再决定是否正式纳管

这不是遗漏，而是有意推迟。

## 10. 你现在可以把 `infra/` 当成什么

现在这个 `infra/`，你可以把它理解成：

- `inventory/`
  - 负责盘点 live
- `stacks/`
  - 负责正式纳管的资源
- `Taskfile`
  - 负责统一入口
- `cloudflare/*.md`
  - 负责记录策略和边界

也就是说，`infra/` 现在已经从“试验目录”变成了“可维护的资源层入口”。

它还不是一个特别重的平台工程，但已经足够支撑你当前这类 Cloudflare 资源维护工作。

## 11. 最终建议

后续请尽量坚持下面这套习惯：

1. 改资源前，先 `inventory` 或至少先 `plan`
2. 日常优先改 `locals.tf`，不要回到手写资源块
3. 默认按单个 stack 做 `apply`
4. 删除已有 live 资源时，始终记住 adopt/delete 两轮模型
5. 只把真正需要长期维护的资源留在 stack 里
6. dashboard 作为观察面，不要重新变回主要写入面

如果把这次工作的最终结论压成一句话：

Cloudflare 这条线已经从“手工 dashboard + 漂移失控”进入了“inventory 驱动、stack 分治、state 可追踪、task 可执行”的状态，后续维护应继续沿着这条路径走，而不是回退到旧 taskfile 或零散 HCL 的做法。
