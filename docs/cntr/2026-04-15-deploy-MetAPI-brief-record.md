---
title: 简要记录部署MetAPI
date: 2026-04-15
isOriginal: true
---

:::tip

本身没啥好记录的，初级开发都能做完的，本地已经跑通了之后，要弄到VPS上，无非是三步：

- 1、同步compose相关配置
- 2、把这个 MetAPI 和 caddy 的 compose 跑起来
- 3、验证是否可用域名访问

但是这里需要注意一些细节问题：

- 为啥选择 `pure docker compose`方案，而非什么 dokku, dokploy 又或者 portainer 之类的方案?
- sops处理 compose.yml 里的secret
- 通过 terraform 来实现 DNS记录的sync
- tailscale 的 `Taildrop` 具体使用

下面就对这些问题，做出简要解答

:::


## 为啥选择 pure docker compose?

简单来说，这个方案是维护成本最低、操作最简单的。

上面列出的其他这几个方案，其实都是增加了一个“控制面”，基于web去做应用的状态变更，不够“声明式”，并且也都有相应的“前置成本”，所以选择直接用 compose去跑。


## ***怎么处理 compose.yml 里的 secret?***

:::tip[TLDR]

这部分简单比较了几种处理 compose.yml 里 secrets的方案。

得出结论：compose 下确实没有“特别好”的 secrets 管理方案（或者说，其实k8s的主流secrets管理方案也都是基于外部服务的，但是对于compose的核心场景，又没必要做的这么复杂，所以会让人产生这样的印象“Compose 缺少 K8s 那种更自动化的体验”）

最终使用 `sops + .env`

:::


```yaml

- 环境变量 + .env 文件（最常见开发方案）   # 在 compose.yml 中使用 env_file: .env 或 environment:，敏感值放在 .env（gitignore 掉）。
- Docker Compose Secrets（文件挂载方式）  # 使用 secrets: 顶层定义 + 服务引用，秘密以只读文件形式挂载到容器 /run/secrets/ 下（Compose v3+ 原生支持）。
- Docker Swarm Secrets（外部秘密）  # 用 docker secret create 创建秘密，compose.yml 中 secrets: xxx: external: true，仅在 Swarm 模式（docker stack deploy）下生效。
- 集成外部秘密管理器（Vault / AWS Secrets Manager / Doppler 等）  # Compose 中不存放秘密值，由 entrypoint 脚本或 sidecar 在运行时动态拉取（或结合 SOPS 加密 .env）。

```

简单来说，***在我看来这4种方案，应该把env排除在外。剩下的3个里，前两个其实都是 docker 内置方案（是否使用了 docker swarm），最后一个就是 外部secret工具。***

两种原生方案其实没啥好讨论的，swarm 本身并不主流，而 `compose secrets`则需要依赖外部文件传递这些secret，但是这些secrets怎么在开源情况下做到加密呢？如果是这种情况下为啥不用 `sops`? ，这就是我说的原声secrets方案没有“全生命周期管理”。

External Secrets Tools 则更成熟，但是问题在于更复杂，强依赖于外部服务。

所以最终选择了 `sops`，这样就可以解决上面列出的这两种问题（既***不依赖外部服务***，也解决了***开源仓库存储 secret 问题***）。并且我的NixOS本身就用了sops，可以直接使用。多说一句，其实这个方案也是近两年社区比较推荐的方案。得到这个结论的过程，思路与我上面的分析过程也基本一致。


```shell
# 加密: .env -> .env.sops
sops --encrypt --age <key> .env > .env.sops

# 解密: .env.sops -> .env
# 这个解密操作可以直接配置到 CICD里
sops -d .env.sops > .env
```


*当然其实 sops 也可以跟上面所说的 `Compose Secrets原生方案`搭配使用。具体来说，用 SOPS 加密 `./secrets/*.txt`，部署时解密后挂载到 `/run/secrets/`，这样既 Git 安全，又运行时不暴露到 env*









## 怎么用 terraform 来把DNS记录刷到 cloudflare?

:::tip

决定用 tf （而非直接在 cloudflare dashboard）把DNS记录刷到 cloudflare

:::

其实很简单，以下几步：

- 1、`infra/stacks/homelab/cloudflare/lucc.dev/dns/locals.tf` 的 `dns_records_managed` 里面添加这个 MetAPI 的 DNS记录
- 2、本地check是否可用

```shell
tofu fmt -check infra/stacks/homelab/cloudflare/lucc.dev/dns

tofu init -backend=false -input=false && tofu validate

```

***按理说上面ok之后，直接plan + apply 即可***


```shell

task tf:plan STACK=infra/stacks/homelab/cloudflare/lucc.dev/dns

task tf:apply STACK=infra/stacks/homelab/cloudflare/lucc.dev/dns

```


***但是在执行 plan 时，发现报了这个warning***

```text
Warning: Resource not found
with cloudflare_dns_record.records["bc"]
The resource was not found on the server and will be removed from state.
```

在我移除掉这个 `bc` 相关的配置之后，在执行plan后，仍然会有这个报错

排查后发现


不是代码里还在引用 `bc`，而是：

- `bc` 这条资源已经不在 Cloudflare live 里
- 但 remote state 里仍然残留着 `cloudflare_dns_record.records["bc"]`

也就是说，这是一个 stale state 问题，而不是 HCL 配置问题。


所以执行

```shell


task tf:state-rm \
    STACK=infra/stacks/homelab/cloudflare/lucc.dev/dns \
    ADDRESS='cloudflare_dns_record.records["bc"]'

```

返回的是：

```text
Error: Invalid target address
No matching objects found.
```

这不表示失败，而表示：

- 当前 remote state 里已经没有 `bc` 这条实例了
- stale state 已经被清理掉

所以这一步最终不需要额外再做人工 `state rm`。


之后再去执行上面的 `plan + apply`，确认没有问题后，就完成该操作了。


---

:::danger

这里再插一句：

问题：`apply` 时 Cloudflare 返回 403

执行：

```bash
task tf:apply STACK=infra/stacks/homelab/cloudflare/lucc.dev/dns
```

时报错：

```text
403 Forbidden
code: 10000
message: Authentication error
```

核心问题在于之前的 cf token 是个 read-all权限，没有 write权限

先后尝试了


:::





## 域名无法直接访问

:::tip

这次问题的核心，***不在 MetAPI 本身***，而在“域名入口链路”。

实际排查结果分两层：

- `metapi` 容器本身是正常的，`4000` 端口可访问
- docker 里的 `caddy` 也确实起来了
- 但公网 `80/443` 并没有稳定落到这套 `caddy -> metapi` 链路上

:::

### 具体是什么问题？

先看应用层：

- `metapi` 在 VPS 上直接访问 `127.0.0.1:4000` / `142.171.154.61:4000` 都是正常 `200`
- 所以应用本身没有挂

再看入口层，发现有两类残留问题叠在一起：

- 1、机器上残留了一套旧的 `k3s/containerd/traefik` 运行态
- 2、即使相关进程停掉了，宿主机里仍然残留 `iptables` 的 `KUBE-SERVICES` 规则，把公网 `80/443` 继续劫持到旧的 `networking/traefik` Service

也就是说，表面上看是 docker 的 `caddy` 在监听 `80/443`，但实际上公网流量先被旧的 k3s 规则截走了。

### 为什么会这样？

虽然在 [hosts/nixos-vps/default.nix](/Users/luck/Desktop/dotfiles/hosts/nixos-vps/default.nix) 里已经设置了：

```nix
modules.extra.k3s = {
  enable = false;
  role = "agent";
  serverPort = 6443;
};
```

但是这只能说明“当前声明式配置不再启用 k3s 模块”，***不代表线上旧的运行态一定已经被彻底清干净***。

这次线上实际看到的是：

- `k3s.service` / `k3s-agent.service` unit 已经不存在
- 但旧的 `containerd-shim-runc-v2` 还活着
- 它托管出来的 `traefik` 进程也还活着
- `iptables -t nat` 里还保留了 `networking/traefik:web` 和 `networking/traefik:websecure` 的 external-IP 规则

所以这是一个典型的 ***“配置已禁用，但旧运行态和旧 NAT 规则仍残留”*** 的问题。

### 核心现象是什么？

排查时先后看到过这些现象：

- `https://api.lucc.dev/` 外部访问拿到的是 `TRAEFIK DEFAULT CERT`
- `caddy` ACME 日志里反复出现：
  - `tls-alpn-01: remote error: tls: unrecognized name`
  - `http-01: Invalid response ... 404`
  - 后续在清掉旧 NAT 规则前，还出现过 `Connection refused`

这些都说明：

- 域名虽然最终是想走 `caddy`
- 但公网挑战流量并没有稳定到达 `caddy`
- 所以 Let’s Encrypt 无法完成校验，自然也就没法签出证书

### 这次怎么解决的？

为了避免后面另一台机器也重复手工排查，这次直接补了一个可复用脚本：

- [k3s-residue-cleanup.sh](scripts/k3s-residue-cleanup.sh)

并配了最小回归测试：

- [test_k3s_residue_cleanup.sh](scripts/test_k3s_residue_cleanup.sh)

脚本做的事情很保守：

- 默认只读 `inspect`
- 只有 `--apply` 才执行清理
- 不碰 Docker 容器
- 不删除数据目录
- 只清理：
  - `k3s/containerd-shim/traefik` 残留进程
  - 残留的 `iptables nat` external-IP 规则

本次已经在这两台机器上执行过：

- `142.171.154.61`
- `103.85.224.63`

执行后，`142.171.154.61` 的公网 `80` 已经重新回到 docker `caddy`，不再被旧 k3s Traefik 劫持。


### 之后有哪些注意点？

- 1、`modules.extra.k3s.enable = false` 只代表配置层禁用，不代表运行态一定自动清干净
- 2、停掉 k3s 之后，要连带检查：
  - 残留 `containerd-shim`
  - 残留 `traefik`
  - 残留 `iptables -t nat` 的 `KUBE-SERVICES` / external-IP 规则
- 3、碰到“容器正常但域名不可达”时，先区分三层：
  - 应用层：服务本身是否正常
  - 入口层：80/443 实际落到了谁
  - DNS 层：公网解析是否真指向当前主机
- 4、ACME 报错非常有价值，不要跳过：
  - `404` 多半表示 challenge 没到正确处理器
  - `TRAEFIK DEFAULT CERT` 往往说明流量进了错误的入口
  - `Connection refused` 往往说明公网入口仍被旧 NAT/旧转发规则影响
