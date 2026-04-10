---
title: colmena-vs-deploy-rs-source-review
type: review
status: active
date: 2026-02-10
updated: 2026-04-01
isOriginal: false
tags:
  - nix
  - nixos
  - colmena
  - deploy-rs
summary: 从源码层面解释 Colmena 与 deploy-rs 在并发部署、速度体感、magic rollback 与全局检查范围上的实现差异。
---


:::tip[TLDR]

本文是 [deploy-rs-migration](2026-01-20-deploy-rs-migration.md) 的后续

在使用了一段时间deploy-rs之后，结合使用体验以及发现的一些问题。所以写这篇blog来做个总结，顺便解惑。

---

本文的基本逻辑是：

从源码层面，去解答以下问题：

- 为啥 colmena 支持并发 deploy，而deploy-rs 只支持顺序deploy？
- deploy-rs为啥deploy很慢？
- deploy-rs是怎么实现 magic- rollback 的？

这三个问题的谜底是一码事吗？还是说并不同？以及是否还有其他相关问题？

***最终再结合这几个核心问题，聊聊 选择 colmena 又或者 deploy-rs 的得失（也就是我们做技术选型时的一些参考）***

:::


这篇不是“功能对比表”，而是直接看实现路径，回答四个迁移中最容易混淆的问题：并发模型、速度体感、magic rollback 协议、以及验证范围。文末再回扣到 [deploy-rs-migration](2026-01-20-deploy-rs-migration.md) 的迁移取舍。






## 问题一：为什么 Colmena 能并发 deploy，而 deploy-rs 默认主流程更接近顺序 deploy

先说结论：这是调度模型差异，不是文档包装差异。

- **源码事实（Colmena）**：命令入口就暴露并发参数，且有独立并发限制结构（含 `apply` 默认并发 10）。
- **源码事实（Colmena）**：部署阶段通过 futures 聚合并使用 `join_all` 推进。
- **源码事实（deploy-rs）**：默认 CLI 主流程是三个阶段化顺序循环：build 全部、push 全部、deploy 全部。

```rust title="colmena/src/command/apply.rs:L1-L40"
#[derive(Debug, Args)]
pub struct DeployOpts {
    #[arg(value_name = "LIMIT", default_value_t = 10, long, short)]
    parallel: usize,
}
```

```rust title="colmena/src/nix/deployment/limits.rs:L1-L24"
pub struct ParallelismLimit {
    pub evaluation: Semaphore,
    pub apply: Semaphore,
}

impl Default for ParallelismLimit {
    fn default() -> Self {
        Self {
            evaluation: Semaphore::new(1),
            apply: Semaphore::new(10),
        }
    }
}
```

```rust title="colmena/src/nix/deployment/mod.rs:L70-L150"
for chunk in targets.drain().chunks(eval_limit).into_iter() {
    futures.push(self.execute_one_chunk(parent.clone(), map));
}

join_all(futures).await
```

```rust title="deploy-rs/src/cli.rs:L470-L560"
for data in data_iter() {
    deploy::push::build_profile(data).await?;
}

for data in data_iter() {
    deploy::push::push_profile(data).await?;
}

for (_, deploy_data, deploy_defs) in &parts {
    deploy::deploy::deploy_profile(deploy_data, deploy_defs, dry_activate, boot).await?;
}
```

- **推断**：在节点数和 profile 数上来后，Colmena 更容易把“多目标阶段”并行化，而 deploy-rs 的默认 CLI 编排更偏“阶段内串行、阶段间推进”的形态。这里只能说明主流程调度模型，不等于证明 deploy-rs 在所有内部实现或所有入口上都完全没有并发。

## 问题二：为什么 deploy-rs 经常让人感觉更慢

诚如我之前写的一个问题

```markdown
有个关于nixos的问题

我之前使用colmena，现在使用 deploy-rs

为啥我感觉相同的配置，但是现在rebuild就是比之前慢很多呢？

这个正常吗？社区有人反馈这个issue吗？
```

---

如果把“慢”只归因为串行，会漏掉另外两层成本。更接近源码事实的拆解是：

1. 调度层：默认顺序 build/push/activate。
2. 传输层：copy 策略会切换，非 fast 连接下默认加 `--substitute-on-destination`。
3. 激活层：启用 magic rollback 时，激活后还有确认窗口。

```rust title="deploy-rs/src/push.rs:L120-L170"
copy_command.arg("copy");
if data.deploy_data.merged_settings.fast_connection != Some(true) {
    copy_command.arg("--substitute-on-destination");
}
```

```rust title="deploy-rs/src/push.rs:L70-L120"
Command::new("nix")
    .arg("copy")
    .arg("-s")
    .arg("--to")
    .arg(&store_address)
    .arg("--derivation")
    .arg(derivation_name);

Command::new("nix")
    .arg("build")
    .arg(derivation_name)
    .arg("--store")
    .arg(&store_address);
```

- **源码事实**：`fast_connection` 与 `remoteBuild` 会直接改变 push/build 路径，尤其是远端构建时的 `copy --derivation` + 远端 `build --store ssh-ng://...`。
- **推断**：`--substitute-on-destination` 本身不是“天然更慢”的开关，而是把 substituting 的责任更多交给目标端。目标端网络、缓存命中率、substituter 可用性不同，可能让它更快，也可能更慢。deploy-rs 的“体感更慢”更接近多种策略权衡叠加后的结果，而不是一句“工具实现差”。

## 问题三：deploy-rs 的 magic rollback 到底是怎么实现的

如果只看 README，容易理解成“失败后自动回滚一次”。就目前能直接看到的源码片段而言，更稳妥的说法是：deploy-rs 在客户端侧把激活流程组织成了一个 `activate -> wait -> confirm` 协议。

```rust title="deploy-rs/src/deploy.rs:L360-L470"
let self_activate_command = build_activate_command(... --magic-rollback ...);
let self_wait_command = build_wait_command(...);

let mut ssh_activate_child = ssh_activate_command.arg(self_activate_command).spawn()?;
let mut ssh_wait_child = ssh_wait_command.arg(self_wait_command).spawn()?;

tokio::select! {
    x = ssh_wait_child.wait() => { ... }
    x = recv_activate => { ... }
}
```

```rust title="deploy-rs/src/deploy.rs:L120-L170"
let mut confirm_command = format!("rm {}", lock_path.display());
let mut ssh_confirm_child = ssh_confirm_command.arg(confirm_command).spawn()?;
```

```rust title="deploy-rs/src/cli.rs:L560-L640"
if rollback_succeeded && cmd_overrides.auto_rollback.unwrap_or(true) {
    for (deploy_data, deploy_defs) in &succeeded {
        deploy::deploy::revoke(*deploy_data, *deploy_defs).await?;
    }
}
```

- **源码事实**：这里至少能确认两层机制。
- `magicRollback`：单目标激活时会带上 `--magic-rollback`、`--confirm-timeout`，并在客户端侧额外跑 `wait` 与 `confirm`。
- `rollback_succeeded`：批量部署后续失败时，对已成功目标执行 `revoke`。
- **推断**：从这条调用链可以 reasonably infer，deploy-rs 把“是否被确认”纳入了激活协议本身，而不是只在失败后补一条手工 rollback。至于“未确认后远端具体如何执行回退”，还需要继续追 `activate-rs` 二进制内部实现，本文先不超出当前证据下结论。

---


> 另外，这里要注意一点，这个 magic-rollback 并非一定保证成功，其实失败频率并不低。并且正如众做周知的，nix的deploy并非真正原子性的（本质上还是过程式的，可以做个实验，在deploy到一半时，kill掉deploy进程，会发现只有部分修改symlink了），这个是nix底层机制，所以这个 magic-rollback 并没有那么有意义。




## 补充问题：为什么 deploy-rs 更容易在部署前暴露“别的 host 也有问题”

这里要精确表述：deploy-rs 的优势不在 deploy 运行期自动检查所有 host，而在它提供了标准化 `deployChecks` 出口，便于把整份 `self.deploy` 接进 flake checks。

```nix title="deploy-rs/flake.nix:L90-L135"
deployChecks = deploy: builtins.mapAttrs (_: check: check deploy) {
  deploy-schema = deploy: ... builtins.toJSON deploy ...
  deploy-activate = deploy:
    let
      profiles = builtins.concatLists (
        final.lib.mapAttrsToList (nodeName: node:
          final.lib.mapAttrsToList (profileName: profile: [ (toString profile.path) nodeName profileName ]) node.profiles
        ) deploy.nodes
      );
```

```nix title="deploy-rs/examples/system/flake.nix:L35-L38"
checks = builtins.mapAttrs
  (system: deployLib: deployLib.deployChecks self.deploy)
  deploy-rs.lib;
```

相对地，Colmena 的 `apply` 路径是“先筛节点，再求值选中节点”。

```rust title="colmena/src/command/apply.rs:L40-L90"
let targets = hive
    .select_nodes(node_filter.on.clone(), ssh_config, goal.requires_target_host())
    .await?;
```

```rust title="colmena/src/nix/hive/mod.rs:L90-L150"
let mut node_configs = if let Some(configs) = node_configs {
    configs
} else {
    self.deployment_info_selected(&selected_nodes).await?
};
```

```rust title="colmena/src/nix/hive/mod.rs:L360-L420"
pub async fn eval_selected(&self, nodes: &[NodeName], ...) -> ColmenaResult<HashMap<NodeName, ProfileDerivation>> {
    let expr = format!("hive.evalSelectedDrvPaths{}", nodes_expr.expression());
    ...
}
```

- **源码事实**：Colmena 默认执行路径偏向“选中节点范围”的 evaluation/apply。
- **推断**：这并不表示 Colmena 不能做全局检查，而是它没有 deploy-rs 这种“标准 `deployChecks` 直接挂 flake checks”的出口形态。反过来说，deploy-rs 这边的“全局检查”也主要发生在你显式接入 `deployChecks` 并运行 `nix flake check` 之类的检查链路时，而不是 deploy 命令在运行期自动替你扫描整个 fleet。再进一步，Nix 的惰性求值也会影响“全局”到底被强制到了哪一层，所以更准确的说法应该是：deploy-rs 更容易把整份部署定义纳入统一检查，而不是无条件检查一切。

## 总结：回到这次从 Colmena 迁移到 deploy-rs 的得失

结合 `docs/deploy/2026-01-20-deploy-rs-migration.md`，这次复盘可收束为一句话：两者不是同层“谁更强”，而是“把复杂度放在哪一层”不同。

- 如果目标主要是 NixOS，且你更看重多节点并发 rollout 与编排效率，Colmena 的模型很顺手。
- 如果你更看重 multi-profile、flake checks 下的部署定义校验、以及 activation 后确认/回滚协议，deploy-rs 更贴合。
- 从 Colmena 迁到 deploy-rs 时，最常见误判是把“更慢”直接等于“更差”；更准确是 deploy-rs 默认承担了更多风险控制路径。

最终判断标准不是 CLI 体验偏好，而是团队希望把风险控制放在部署前检查、部署中确认，还是放在操作者手工流程里。

---


:::tip


综合来说，从 colmena 迁移到 deploy-rs，正如上文所说，本身是为了 `multi-profile`才做的迁移（为了让代码更简洁、可维护性更好，正如从 haumea -> flake-parts一样，原因都大差不差），迁移过来后，并没预期中的那么好，但是确实有得有失，deploy体验确实不如之前那么好了，但是也确实有所得。也懒得再迁移回去了。

:::
