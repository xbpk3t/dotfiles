# .cntr — Compose service inventory

> **单一控制面：Docker Compose。**
> Nix 只负责把 `.cntr` 分发到 `~/.cntr`（`home/core/devops/cntr.nix`），
> 不管理容器生命周期。不要在这里引入 `virtualisation.oci-containers`，
> 除非通过 LUC-515 的 5 项准入测试。

## 日常操作

```bash
# 在 dotfiles 仓库内：task <name>
# 在任意目录（VPS 日常）：task -g <name>（~/.taskfile 由 HM 分发）

# 收敛所有 stack（幂等；先创建 edge 网络；单 stack 失败不阻断其他）
task cntr:reconcile

# 查看运行态
task cntr:status

# 对比 compose 配置与运行容器（config-hash）
task cntr:diff

# 本地验证（不碰 ~/.cntr）
CNTR_DIR=./.cntr CNTR_DRY_RUN=true task cntr:reconcile
```

可用环境变量：

| 变量 | 默认 | 说明 |
|------|------|------|
| `CNTR_DIR` | `~/.cntr` | compose 根目录 |
| `CNTR_ENV_FILE` | `~/.config/cntr/env` | sops 渲染的 compose env；存在才使用 |
| `CNTR_DRY_RUN` | `false` | 只打印将执行的命令 |
| `CNTR_INCLUDE_DEV` | `false` | 包含 `golang` 本地 sandbox |
| `CNTR_STRICT` | `false` | `status`/`diff` 以非零退出码表示漂移 |

`sops` 渲染的 env（`~/.config/cntr/env`）包含：
`DEFAULT_SK`、`GITHUB_TOKEN`、`RESEND_TOKEN`、`EDGE_NETWORK_EXTERNAL=true`。
不在仓库里保存明文。

## 服务登记表

| Stack | 容器 | 入口 | 网络 | 持久化 | 备份 | 更新 |
|-------|------|------|------|--------|------|------|
| `caddy` | caddy:2 | `:80/:443`；api/rsshub/as.lucc.dev | edge | `./data`, `./config` | — | 手动（不在 watchtower） |
| `axonhub` | axonhub:latest, postgres:15-alpine, 9router:latest, resin:latest, cpa:latest, cpamp:latest, register-lite:latest | `127.0.0.1:8090/20228/2260/8317/18317/8788` + edge | edge | named volumes + `./CPA/auth-dir`, `./resin/*` | `backup-pgsql.nu axonhub`（`axonhub-pgsql`） | watchtower: axonhub/9router/resin/cpa；其余手动 |
| `rsshub` | rsshub:latest, browserless:1.43-chrome-stable | edge（caddy 反代） | edge | — | — | watchtower |
| `openlist` | openlistteam/openlist:latest | edge（caddy 反代） | edge | `./data`, `./downloads` | — | watchtower |
| `rustdesk` | rustdesk/rustdesk-server（无 tag） | `:21114-21119` | `rust_desk_net` | named volumes | — | 手动 |
| `actions-runner` | myoung34/github-runner:2.338.2 | 无 | default | `runner_data` + `~/.opencli/xiaoyuzhou.json` | — | 手动；**必须**保持 `DISABLE_AUTO_UPDATE` |
| `watchtower` | containrrr/watchtower:latest | 无 | default | `docker.sock` | — | 自身不纳入 allowlist |
| `golang` | 本地 dev sandbox（profiles） | 本地端口 | `golang_backend` | named volumes | — | 不纳入 reconcile（`CNTR_INCLUDE_DEV=true` 才包含） |

## 边界与约定

- **edge 网络没有 compose owner**：所有 stack 都写 `external: true`，仓库里没有
  `docker network create edge`。`cntr.nu` 会在每次 reconcile 前幂等创建。
- **备份脚本依赖容器名**：`backup-pgsql.nu` 用 `docker ps` 正则
  `^project.*postgres` 找容器；改容器名前先改脚本。
- **watchtower allowlist 是显式的**（`.cntr/watchtower/compose.yml`）：
  `axonhub, 9router, rsshub, resin, cpa, openlist`。新增服务不会自动更新，
  必须显式加白名单。
- **版本策略**：
  - 有状态/入口/CI 关键服务保持 pin：`actions-runner 2.338.2`、`caddy:2`、
    `postgres:15-alpine`、`browserless:1.43-chrome-stable`。
  - 其余 `latest` 服务交给 watchtower；升级失败时用 `task cntr:diff` 定位。
- **不要在 VPS 上手改 `~/.cntr`**：文件是 nix store 的只读 symlink；
  改仓库 → `nixos-rebuild`/HM switch → `task cntr:reconcile`。

## 为什么不做 Nix oci-containers

结论见 Linear **LUC-515**（含完整分析）。摘要：

- 历史三次 Nix 化（NMDC / dokploy-oci / k3s）都因边界对象回退；
- 现役容器大多 `latest` + watchtower，与 Nix 的 pin/generation 语义冲突；
- "长期使用"判据会选中 caddy/axonhub 这两个最难的服务；
- 真正缺的是收敛，不是 lifecycle owner；`cntr:reconcile` 已补上。

若未来要重新评估，先满足 5 项准入测试：连续 6 个月零实质配置变更、单容器或仅
ordering 依赖、镜像已 pin、不使用 compose-only 特性、不碰 edge/caddy/postgres/
watchtower 共享边界。
