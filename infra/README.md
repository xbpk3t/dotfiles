# Infra

`infra/` 现在采用“原生 Terraform/OpenTofu root module + Terramate 编排层”的轻量方案。

这个选择的目标不是把现有代码一次性重写成另一套框架，而是先解决几个更实际的问题：

- 给现有 root module 一个统一的 stack 元数据入口
- 后续新增 stack 时，不再把 provider/backend/命名约定散落在各目录
- 为“盘点现有云资源 -> 逐步纳管到 IaC”留出稳定路径

## 当前约定

现有目录先按两层看待：

- `legacy root modules`
  - 当前已经在跑的 Terraform 目录，先保留原样
  - 例如 `minio/tf-s3-backend`、`minio/loki`
- `future stacks`
  - 新增的基础设施优先放到 `stacks/` 下
  - 由 Terramate 负责做 stack 发现、批量执行、后续统一模板化

目录结构：

```text
infra/
  inventory/
  minio/
    tf-s3-backend/
    loki/
  stacks/
```

## 为什么是 Terramate

这里不引入更重的编排层，原因很简单：

- 现在仓库里的 TF 规模还小，直接上 Atmos 这类平台级框架会过度设计
- Terragrunt 也能做，但更偏 wrapper；这里更需要一个对现有目录侵入更小的编排层
- Terramate 可以先只做 stack 编目，后面再逐步补 code generation 和 orchestration

换句话说，这里先把 Terramate 当作 `flake-parts` 那种“组织层”，不是当成第二套 Terraform 语言。

## 现有 stack

已纳入 Terramate 编目，但暂时仍按 legacy root module 运行：

- `minio/tf-s3-backend`
- `minio/loki`

每个 legacy 目录都加了 `stack.tm.hcl`，目的是先把元数据和后续迁移入口固定下来，不在第一步改 state 布局。

## 后续新目录怎么放

新资源不要继续平铺在 `infra/<provider>/<service>` 下面，优先放在：

```text
infra/stacks/<scope>/<provider>/<service>/
```

建议示例：

```text
infra/stacks/homelab/minio/prometheus/
infra/stacks/homelab/cloudflare/dns/
infra/stacks/vps/cloudflare/zone/
```

这样做的原因：

- `scope` 用来表达部署边界，例如 `homelab`、`vps`
- `provider` 只表示 API 边界，不混业务语义
- `service` 是实际 stack 单元，便于单独 plan/apply

## 盘点现有云资源的流程

你的下一个重点不该是“先写很多 TF”，而是先把现状盘清楚。

推荐流程：

1. 先做 inventory，不直接做重构
2. 按 provider / account / project / region 导出资源列表
3. 把导出结果放进 `inventory/<date>/`
4. 标记哪些资源已经由 IaC 管，哪些还是手工资源
5. 先纳管高价值资源：DNS、对象存储、网络、IAM
6. 最后再用 import / generated config 作为迁移草稿，而不是直接当最终代码

推荐 inventory 目录：

```text
infra/inventory/2026-03-26/
  cloudflare/
  minio/
  aws/
  gcp/
```

每个 provider 下至少保留：

- 账号或租户标识
- 区域
- 资源类型
- 资源名
- 当前是否已被 Terraform/OpenTofu 管理
- 计划归属到哪个 stack

## 迁移策略

这里采用增量迁移，不做一次性翻修：

1. 保留 `minio/tf-s3-backend` 作为 bootstrap stack
2. 保留 `minio/loki` 作为 legacy stack
3. 新增资源统一进入 `stacks/`
4. 等某个 legacy root module 需要大改时，再迁到 `stacks/` 下

这样做可以避免：

- 一开始就改 state key
- 还没盘点完资源就先重构目录
- 为了“框架整齐”打断已有可用配置

## 推荐命令

安装 Terramate 后，可以先用这些命令查看 `infra` 相关 stack 是否正常：

```bash
cd /path/to/dotfiles
terramate list --tags layer-infra
terramate run --tags layer-infra -- terraform plan
```

如果后续切到 OpenTofu，也保留同样的目录组织，只把执行命令换成：

```bash
cd /path/to/dotfiles
terramate run --tags layer-infra -- tofu plan
```

## 下一步

下一步应该优先做下面两件事之一：

- 建第一版 `inventory/<date>/` 盘点清单
- 把第一个“新”基础设施 stack 放到 `stacks/` 下，验证目录约定

不要在这一步先做大规模抽模块。
