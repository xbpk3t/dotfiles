# Generated infra facts

`facts.json` 由 `infra/facts.nix` 求值生成，**不要手改**。

重新生成：

```bash
task tf:facts
```

CI 会重新求值并检查与提交版本无 diff。消费方：

- `infra/stacks/homelab/cloudflare/account/{d1,kv,pages,r2}/locals.tf`
- `infra/stacks/homelab/cloudflare/lucc.dev/{dns,email-routing}/locals.tf`
- `infra/stacks/homelab/cloudflare/lucc.dev/dns/locals.tf` 的共享 DNS 记录
