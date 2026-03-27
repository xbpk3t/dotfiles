# Cloudflare Adoption Plan

这份文档定义 Cloudflare 从 dashboard 历史状态迁移到 Terraform/OpenTofu 的收编方式。

## 1. 资源分组

### zone-scoped

- DNS records
- Email Routing rules
- 后续可以再补 zone rules / zone settings

### account-scoped

- Pages projects
- Workers scripts 的基础设施视角
- D1 databases
- KV namespaces
- R2 buckets

## 2. 第一批适合先纳管的资源

优先级从高到低：

1. DNS
2. Email Routing
3. Pages projects 的配置层
4. D1 / KV / R2 的“资源存在性”与基础属性
5. Workers 的基础设施元数据

暂缓项：

- 高频变动的 Worker code deployment
- 还没形成稳定边界的临时 dashboard 试验项

## 3. inventory 结构

每次盘点输出一组内容：

- `raw/*.json`
  - Cloudflare API 的原始响应
- `summary.json`
  - 归一化后的资源总览
- `README.md`
  - 人可读的盘点摘要

## 4. state 边界

不要做一个巨大的 `cloudflare.tfstate`。

建议未来拆成这些 stack：

```text
infra/stacks/homelab/cloudflare/<zone>/dns/
infra/stacks/homelab/cloudflare/<zone>/email-routing/
infra/stacks/homelab/cloudflare/account/pages/
infra/stacks/homelab/cloudflare/account/d1/
infra/stacks/homelab/cloudflare/account/kv/
infra/stacks/homelab/cloudflare/account/r2/
infra/stacks/homelab/cloudflare/account/workers-infra/
```

这样拆的原因：

- 降低单次 `plan/apply` 的 blast radius
- 避免 DNS 与 Pages / Workers 绑定成一个 state
- 便于逐步 adopt，而不是一次性全收编

## 5. 从 dashboard 历史状态迁到 TF 的顺序

1. 拉 inventory，确认现实状态
2. 标记 ownership
3. 针对单个资源组生成 import candidate
4. 人工审阅并重写成正式 HCL
5. 做第一次 `plan`
6. 目标是先达到 `no-op` 或“只有预期差异”
7. 再把这组资源切换为 Terraform/OpenTofu 作为唯一写入面

## 6. drift 的处理原则

Terraform/OpenTofu 不是双向同步工具。

正确处理方式是：

- dashboard 的历史操作先通过 inventory/import 被吸收
- 一旦某类资源进入 managed 状态，就不应该继续长期手改
- 如果生产上临时手改过，之后必须回写到 HCL

也就是说，长期目标不是“双向一致”，而是“单一写入面 + drift 可发现”。

### 关于“本地注释掉资源后，什么时候会删 live”

这里要特别注意：

- 还没有 import 进 state 的 live 资源，即使你已经在 `locals.tf` 里注释掉，也不会被 OpenTofu 删除
- 因为它对当前 state 来说仍然是“未纳管资源”，不是“已纳管后被移除的资源”

如果你想让某个现有 Cloudflare 资源最终由 OpenTofu 删除，顺序必须是：

1. 先把它保留在当前数据模型里
2. 先执行一次 `plan/apply`，让它 import/adopt 进 state
3. 再从 `locals.tf` 删除或注释掉
4. 再执行下一次 `plan/apply`，这时才会出现真正的 destroy

也就是说：

- 第一次 `apply` 解决的是 adopt
- 第二次 `apply` 才可能解决 delete

## 7. 当前落地状态

已经纳管的 stack：

- `infra/stacks/homelab/cloudflare/lucc.dev/dns/`
- `infra/stacks/homelab/cloudflare/lucc.dev/email-routing/`
- `infra/stacks/homelab/cloudflare/account/d1/`
- `infra/stacks/homelab/cloudflare/account/kv/`
- `infra/stacks/homelab/cloudflare/account/r2/`
- `infra/stacks/homelab/cloudflare/account/pages/`

当前有意暂缓：

- Workers scripts / subdomain

原因：

- provider 可以把 live Worker 导出成 Terraform，但结果会直接内联整段 script code
- bindings 里还可能混入 secret / plain_text / deployment 细节
- 这样会把 code deployment 和 infra state 强耦合，维护性反而更差

因此当前策略是：

- 先保留 Workers 在 inventory 层可见
- 等后续明确每个 Worker 的源码仓库、发布链路、secret ownership 之后
- 再决定是否用 Wrangler / CI / Terraform 的哪一层作为唯一写入面

## 8. backend 策略

Cloudflare stacks 当前统一使用 Cloudflare R2 作为 remote backend，而不是继续依赖旧的 MinIO/S3 落点。

这样做的原因：

- Cloudflare 这条线可以独立维护
- 不再要求额外的旧 backend 凭据
- 更符合“Cloudflare 资源由 Cloudflare 自己托管 state”的边界

例外：

- `luck-dotfiles-opentofu-state` 这个 bucket 本身是 bootstrap bucket
- 它需要先存在，不能由“正在使用它保存 state”的同一套 stack 首次创建
- 因此当前把它视为 external bootstrap resource，并在代码里显式注明
