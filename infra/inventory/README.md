# Inventory

这里用于保存云资源盘点结果。

建议按日期建立子目录：

```text
infra/inventory/2026-03-26/
  cloudflare/
  minio/
  aws/
```

每条盘点记录至少包含：

- provider / account / project
- region
- resource type
- resource name
- 是否已由 Terraform/OpenTofu 管理
- 计划归属到哪个 stack
