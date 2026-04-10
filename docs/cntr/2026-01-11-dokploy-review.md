---
title: 从入门到放弃：半个月速通 dokploy
date: 2026-01-11
isOriginal: true
---

:::warning

今天是2026-03-25，本文是篇迟到的review，早在今年1月使用dokploy（2026-01-05），使用了大概不到一个月就弃用了，本文就是相应记录和存档。

**_注意为了保证record准确性，把本文的date设置为 2026-01-11_**

:::

## 当时为啥迁移到 dokploy

书接前文，之前遇到了

[Docker管理方案演进总结](2025-12-01-container-solutions-for-nixos.md)

里面的问题，核心问题就是“谁是owner”嘛

之后切换到 portainer，用了几天，也就是完全把应用托管给第三方了，非常省心，但是 portainer 不支持数据备份，就很苦恼。当时的记录是

```yaml
- date: 2025-12-05
  des: |
    花了几乎一整个下午去研究【容器数据备份】相关的各种东西，结果看到dokploy本身就支持该功能，真TM浪费时间啊。这里简单记录一下。
    1、【两类备份工具】
    2、这两类备份工具是否必须搭配使用（offen这类工具自己本身不也能备份到S3吗）？具体两类各挑哪个，组合使用？
    3、为啥最终放弃了这套方案，而转去直接用dokploy内置备份功能？

# 1、两类工具（快照工具+备份工具）快照工具支持自动化、加密、增量备份，并能处理数据库一致性问题（如停止容器备份），而备份工具则用来提供更易用的backup和restore操作（以及去重、加密、多版本、远程存储）。前者包括【offen/docker-volume-backup】、【nautical】。后者包括【restic】、【kopia】、【duplicati】之类的。
# 2、并非必须搭配，但是建议搭配使用。“能用和好用是两码事”，具体来说：
## 1、offen 确实内置上传s3，但是不支持块级去重，比如说每天要备份50GB的数据，保留30天，那offen就需要S3上有1.5TB的空间，而如果使用kopia，则只会上传变化的block(增量+去重)，可能只需要不到60GB的空间。
## 2、kopia会提供统一的备份策略管理和数据源管理。比较推荐 offen + kopia 组合使用。
# 3、因为太TM麻烦了。主要在于快照工具，需要手动把所有需要backup的volume，声明式写到offen的volume里（而非打个label就可以自动发现volume），kopia也不支持通过env来配置邮件通知（必须要在WebUI里手动配置（也就是配置入DB））。除了以上问题以外，还有一堆麻烦的问题，懒得记录了。
```

所以就找到了 dokploy

当时初次使用非常顺畅，从安装到所有 remote server的配置乱七八糟的，一共只用了不到40min，就全部搞定了，给了我一个非常好的初印象。

## 为啥最终放弃使用 dokploy?

:::tip

遇到了哪些问题？又尝试怎么解决？为啥最终还是选择放弃使用？

:::

我直接使用

[el-kurto/nix-dokploy](https://github.com/el-kurto/nix-dokploy)

以下是与dokploy相关的4个commit（按照date排序）

[feat(dokploy): 使用 nix-dokploy 这个 flake来作为 dokploy控制面（放在homelab里） · xbpk3t/dotfiles@143761d](https://github.com/xbpk3t/dotfiles/commit/143761d388cd972ca1c7bd363434abff736a9a16)

[feat(dokploy): 添加 dokploy-server.nix 作为 dokploy remote server · xbpk3t/dotfiles@83b9198](https://github.com/xbpk3t/dotfiles/commit/83b919879e334a9ed4877ee40456e511c62c224d)

[fix(dokploy): services.traefik -> docker container 来解决服务504的问题 · xbpk3t/dotfiles@2b1689f](https://github.com/xbpk3t/dotfiles/commit/2b1689f72d5b74847cb4dd4c62253250d70e45f9)

[feat(dokploy): 之前是systemd里跑docker run，改为更NixOS的方案 · xbpk3t/dotfiles@df32376](https://github.com/xbpk3t/dotfiles/commit/df3237669f62f6057fc8d9f74cc227c35cfd9cc4)

总之前前后后大概遇到了以下几个关键问题：

- **_【dokploy与NixOS兼容性问题】dokploy 本身的设计就没考虑过 NixOS，无论 控制面 还是 remote-server 都是如此_**

这点已经做了很多尝试，包括上面的 `83b9198`, `df32376` 都是为了尝试解决这个问题。

- 控制面：modules/nixos/homelab/dokploy.nix
- remote server：modules/nixos/vps/dokploy-server/default.nix

但是仍然无法解决

---

- 【数据restore问题】备份成功的数据无法restore到dokploy
- 【服务状态问题】这个确实解决不了，因为这个问题的核心就在于我们把“应用的owner”交给了 dokploy，而又因为我们用了NixOS，如果是其他 Distro，搞好了就没人乱动了，自然也就不容易出问题，NixOS对于应用管理是需要保证全lifecycle管理的，而我们在做了NixOS的deploy后，经常会发现dokploy服务本身的状态就不一致了。
- 【应用监控】dokploy开源版本不提供应用监控，只有付费托管版本才支持（当时想要废弃掉 beszel，都直接用 dokploy 统一管理）

---

以下是我当时做的记录

```yaml
# Dokploy有很多bug，但是除此之外，别无他选

# 1、添加service时，需要设置 Select a Server。在已经添加后，是否还能修改相应 server呢。要换服务器通常只能 在目标服务器上重新创建一个，再把配置/数据迁过去。

# Dokploy上怎么看到所有service当前状态？
# 即使remote server已经 setup server了。monitor面板里，也看到该server的指标

# 经过几天使用，我发现了大量 Dokploy的问题，或者说 bug很多
# 1、Dokploy并不会持续监控某个container是否真的一直在运行（应用存活/健康检查）。Dokploy上只会显示该服务是否deploy成功了。
# 2、另外，remote server 只支持 debian/ubuntu，即使如此也没有对这两个distro的很多 corner case做出优化。当然，这点也是因为不同公有云平台，即使对于相同的debian:11 也会有不同的预制处理，可能也无法兼顾到各种corner case，但是问题在于任何优化都没有，我尝试把两台VPS（分别是debian:11和debian:13）做init，都有各自的问题，需要手动调整
# 3、还有之前遇到的，Default Server 迁移到其他server时，会遇到问题。目前不支持把已部署资源移动到另一台服务器，只能手动重部署。

# 4. services.traefik 跑在宿主机网络的 namespace 里，但是 Dokploy 的动态回源地址是 swarm overlay网段（10.0.x.x），宿主机根本打不通 overlay IP，于是回源超时，返回504



---
# - 构建资源把机器打爆 / 卡死导致全站受影响
#Dokploy 官方自己在“Going Production”里提醒：nixpacks/buildpacks 构建可能导致超时甚至把服务器“freeze”，建议改成 CI/CD 构建后推镜像。
#
# - AutoDeploy 会清空仓库目录，导致你挂载 repo 内文件后续丢失/变空
#官方 Troubleshooting 直接写了原因：每次部署会重新 git clone，repo 目录会被清空；解决方案是把要挂载的文件放到 Dokploy 的 File Mounts。
#
# - remote server 相关能力不稳定/边缘 bug（日志/域名/容器列表等）
#例如有人报过 remote server 上“看 Swarm/containers 失败、日志/创建域名不可用、UI 弹窗卡死”等。
#
#（这个 issue 最终被关闭为 not planned，但对你判断“remote server 体验是否稳”很有参考价值。）
#
# - 升级/重启后 migration 失败导致服务起不来（曾出现过）
#比如升级后重启 VPS，报 migration failed / 依赖解析失败。
#
# - 最近仍在冒出的线上问题/bug（2025-12 到 2026-01 的 open issues）
#比如：Swarm overlay 网络导致 502、Monitoring 在 UI “Clean all” 后失败、Requests tab 不更新等。
#
# - 安全配置的“错觉坑”
#Dokploy 文档也提醒：Docker 会绕过 UFW 规则，可能让你以为防火墙挡住了但端口其实暴露着。
```

另外还有一点当时很麻烦的，就是会有一个default node，在尝试更换default node后，这些部署好的应用仍然会在之前的node，而非当前node。另外，他这个dokploy只能手动操作来把应用从 node1迁移到 node2，好像还不支持批量迁移，就导致迁移时非常麻烦。总之怎么用怎么不爽。这点是dokploy本身功能缺陷，解决不了。

总之总之，就是搞得一团乱麻

:::tip

**_但是上面这些也只是不好用而已，我深刻反思后，觉得最核心的问题在于：我还是需要一个足够声明式配置的应用部署平台_**

:::



### case-1


```markdown

# Beszel 访问问题处理记录

日期：2026-01-10

## 目标
- 保持 Dokploy 动态路由管理（不写死静态路由）。
- 解决 Traefik 回源 504（宿主机无法访问 overlay 容器 IP）。

## 核心结论
- Traefik 以宿主机 systemd 服务运行时，Dokploy 动态路由回源地址是 overlay IP（如 10.0.1.2:8090），宿主机无法访问，导致 504。
- 需要把 Traefik 切回容器方式加入 `dokploy-network`，与 Dokploy 的动态路由机制一致。

## 已做代码改动（本地）
文件：`modules/nixos/vps/dokploy-server/default.nix`
1) 保持 `/etc/dokploy` 目录结构，ACME 文件由容器写入：
   - `acme.json` owner 改为 `root:root 0600`（容器 root 可写）。
   - 中文注释说明 Traefik 容器写入方式。
2) 移除 systemd 原生 Traefik 服务配置：
   - 删除 `services.traefik` 与 `ReadWritePaths` 等配置。
3) 新增 Traefik 容器服务：
   - `systemd.services.dokploy-traefik`
   - 使用 `docker run` 加入 `dokploy-network`
   - 挂载 `/etc/dokploy/traefik/traefik.yml` 与 `dynamic/`
   - 暴露 80/443（tcp/udp）
   - 采用 `traefik:v3.6.1`

## 远端已验证事实（排障证据）
- Traefik API 显示回源为 overlay IP（示例）：`http://10.0.1.2:8090`
- 宿主机无法访问该 IP：`curl http://10.0.1.2:8090` 超时

## 待执行步骤（生效/验证）
1) 通过 colmena / nixos-rebuild 应用配置。
2) 在服务器执行：
   - `sudo systemctl stop traefik`（确保旧 systemd Traefik 不占用端口）
   - `sudo systemctl start dokploy-traefik`
3) 验证：
   - `curl -I -H "Host: beszel.lucc.dev" http://127.0.0.1`
   - `curl -vk --resolve beszel.lucc.dev:443:127.0.0.1 https://beszel.lucc.dev --max-time 10`
   - `curl -s http://127.0.0.1:8080/api/http/services | jq '.[] | {name:.name, servers:.loadBalancer.servers}'`
     期望回源地址为可访问的容器内部网络地址（overlay 可达，因为 Traefik 也在 overlay 内）。

## 备注
- 本次方案严格依赖 Dokploy 动态路由，不新增静态 file provider 路由。

```




## 换成什么方案？

```yaml
# 我对Dokploy的核心需求在于：
# 1、在Dashboard直接配置域名（Dokploy通过traefik直接注入label实现）
# 2、备份volme和DB
# 3、在线查看Deployment状态（包括分stage (dev, prod 之类的)）
# 4、remote server
# k3s生态下是否有完全对标，以及支持这些操作的工具？
```

得到的回答是

```yaml
# 如果你的目标是：
#同一个 Dashboard 里：配域名、备份卷/DB、看部署状态+环境、管远端服务器
#那在 K3s 里通常是这种组合思路：
#入口/域名：K3s + Traefik（Ingress/IngressRoute）
#管理面板：Rancher（看资源、日志、rollout、多集群）
#备份：Velero（资源+PV 数据）+ DB 原生备份策略（CronJob/Operator）
#集群灾备：K3s etcd snapshot to S3
#这套在能力上能覆盖你列的 1-4，但它确实不是“一键替换 Dokploy”的体验。
```

所以最终切换到了 k3s，

lifecycle owner 是 GitOps (fluxcd)

至于 运维平台则使用 Headlamp，只用来查看，SSOT 是 git，而非 web上的操作

## 锐评“运维面板”

```yaml
- date: 2025-07-31
  des: |
    移除之前做的“【技术选型】运维面板”。结论在前：只保留1Panel，其他全部移除。具体来说，通过xxx，又加深了对运维面板的理解。还是用3w3h框架。

    【what】运维面板的核心能力。运维面板 = 拨测工具（监控）+ 安全防护（WAF防火墙、TLS证书、操作日志）+ 基础运维工具（文件管理、容器自动化部署） + 应用备份恢复。

    这里也就来说明上面的定位问题，相较于其他类似工具，运维面板的核心在于日志审计？这是其独一无二的能力。剩下的几个核心能力，我们逐项来说，1、自动化部署。但是如果我用CICD的话，直接自动化部署了，那就肯定不需要手动触发部署了。2、监控及报警，肯定是不如prom好用的，也就只能提供拨测。3、数据备份 则可以轻易实现，实际上并不能作为核心能力。

    那么综上所述，我们可以清晰得到运维面板的定位。没用微服务，没用k8s，也没有用prom之类的ms生态。注意这三个条件都需要满足。（这里需要注意，单机也可以用k8s部署，也可以使用prom）。这也就是运维面板的【why】。

    最后结合以上基本认知，来逐项说明为啥移除其他工具。
    【Nging】功能泛而不精，在容器化与微服务场景中缺乏深度集成能力（如K8s编排/Service Mesh支持），同时监控与审计能力弱于Prometheus+堡垒机组合，导致在专业运维体系中价值稀释。

    【Webmin】架构陈旧且扩展性差，仅支持传统*nix系统管理，无法有效管理容器、云原生应用及多云环境，与现代DevOps工具链完全脱节。可以用TF+ansible上位替代。

    【Cockpit】定位尴尬，作为轻量级基础监控工具，既不具备运维面板的完整管理功能（如Web服务器配置、计划任务），也缺乏企业级安全审计能力，沦为“高不成低不就”的过渡方案

    ---
    【2025-09-22】移除【1Panel】用了nix之后，确实用不到这玩意，太糙了。
    【2025-11-28】移除【Nexterm】，分两点说：1、之后不再看这种web形式的运维面板了。2、
```

这里想拓展锐评一下“运维面板”，也算是给相关认知打个 milestone

我现在对这类东西的判断已经很明确了：`运维面板不是终局方案，而是过渡性产品。`

它们最大的卖点当然有价值，就是 `省心`。把部署、反代、证书、文件管理、计划任务、容器、备份、基础监控这些杂事，全都塞进一个 Web UI 里，初期体验往往非常爽，尤其适合“先把东西跑起来”。但问题也恰恰出在这里：`为了追求一站式，最后往往变成什么都能碰一点，但没有一个能力真正做到专业。`

这类产品的通病其实很稳定：

- 【安全面普遍偏弱】Web 面板本身就是高价值攻击入口，而这类东西往往又天然握着高权限，隔三差五爆出 CVE 根本不意外。
- 【抽象层级太浅】它们通常只能覆盖最常见的 80% 场景，一旦进入复杂网络、复杂部署、复杂权限、复杂排障，马上就露馅。
- 【状态容易漂移】尤其当你开始引入 `NixOS`、`Terraform`、`Ansible`、`GitOps` 这种声明式体系之后，面板就会变成第二真相源，最后最难受的不是“不好用”，而是“它在偷偷改系统，而系统也在反过来覆盖它”。
- 【观测和审计能力通常也不够】很多时候提供的只是“状态展示”或者简单拨测，离真正的 observability 和治理体系差得还很远。
- 【UI 普遍很丑】丑还只是表层问题，更关键的是信息架构经常很乱，关键状态、失败原因、依赖关系、权限边界都表达不清，看似什么都能管，实际一到排障就很费劲。

所以我现在更愿意把这类东西分成三层来看：

- `主机面板型`：核心是“把宿主机运维网页化”，比如 `1Panel`、`宝塔`、`Webmin`
- `应用管理面板型`：核心是“把应用部署流程产品化”，比如 `Dokploy`、`Coolify`
- `集群控制面型`：核心是“站在编排系统之上做治理入口”，比如各类 `Kubernetes` 控制面

如果只看体系成熟度、扩展性和长期上限，可以近似理解为：

`集群控制面型 > 应用管理面板型 > 主机面板型`

原因不是前者“更高级”这么简单，而是它背后的抽象层级更高。`主机面板型` 本质上还是在管机器，`应用管理面板型` 是在管部署生命周期，而 `集群控制面型` 已经是在成熟编排系统之上做资源治理与策略收口了。前两者更像“把常见运维动作做成产品套餐”，后者更像“把一组专业基础设施接进同一个控制平面”。

所以我的最终判断是：`运维面板真正解决的是“省心”，不是“专业”；解决的是“先跑起来”，不是“长期可治理”。`

这也是为什么，随着基础设施逐渐声明式化、观测体系逐渐专业化、应用部署逐渐 GitOps 化之后，我越来越不愿意把这类东西当成长期基础设施。它们当然能用，甚至在某些阶段还很好用；但一旦体系开始成型，这类产品就很容易从“效率工具”退化成“历史包袱”。

## 相关Archive

```yaml
- url: https://github.com/Dokploy/dokploy
  doc: https://docs.dokploy.com/docs/core
  des: 【运维面板】
  rel:
    - url: https://github.com/el-kurto/nix-dokploy
      des: 用来在NixOS部署 Dokploy控制面（注意不包括Remote Server）

    - url: https://github.com/railwayapp/railpack
    - url: https://github.com/railwayapp/nixpacks # https://mynixos.com/nixpkgs/package/nixpacks
    - url: https://github.com/buildpacks/pack
```

<details>
<summary>相关3w3h</summary>

```yaml
why:
  - 【简化部署痛点】为什么需要简化应用管理？Dokploy 提供一键部署，解决传统手动配置的复杂性和时间消耗
  - 【成本节约价值】如何降低云服务费用？作为免费自托管 PaaS，避免 Vercel 或 Heroku 的订阅费，只需一台服务器
  - 【数据控制需求】为什么追求自托管？帮助用户保持数据隐私和控制权，适合对云依赖有顾虑的开发者
  - 【易用性优势】Dokploy 如何提升效率？直观的 UI 界面简化从开发到生产的流程，减少学习曲线

  # [Coolify vs Dokploy: Why I decided to use one over the other](https://blog.dreamsofcode.io/coolify-vs-dokploy-why-i-decided-to-use-one-over-the-other)
  - 【技术选型】

what:
  - 【】如果用一句话概括二者的区别，你会怎么说？也就是说二者的核心区别在于什么？
  # **一句话：Dokploy 的核心是“用容器/Traefik/Swarm 把应用当产品来部署与运营（PaaS 化）”，而 1Panel 的核心是“把一台服务器当对象来运维与建站（主机面板化）”。**

  #  - 那二者各自的主要矛盾是什么（或者说，各自解决了什么核心问题）？分别用一句话概括。为啥能认为 Dokploy 像对于 1panel 是迭代？
  #
  #  - **1Panel 的主要矛盾 / 核心问题**：在“让单机/少量服务器的建站与日常运维足够简单可视化”与“主机层配置千变万化、容易变成雪花机且难以标准化复用”之间做取舍——它解决的是**主机运维与建站的一站式门槛问题**。
  #  - **Dokploy 的主要矛盾 / 核心问题**：在“把应用部署做成平台化（Git/镜像/环境/入口/数据库/备份一体）”与“容器应用本身高度自由、各项目差异大”之间做取舍——它解决的是**多应用容器化部署的集中治理问题**。
  #
  #  - **为什么能认为 Dokploy 是对 1Panel 的“迭代”（更准确说是范式升级）？**
  #  - 因为它把运维的“对象”从**服务器**（改配置、装软件、管站点）升级为**应用**（交付、路由、依赖、备份、环境），用容器平台把大量“主机手工活”上移为“应用生命周期管理”，更贴近现代 DevOps 的工作流；但注意这不是对所有场景都更好——只是对“容器优先/多应用/多机”的场景更像下一代。
  - 综合评价：我感觉这类东西能否认为就是新时代的运维面板？用来取代 宝塔、1panel, nging 之类这些的？这个说法有百分之多少是有正确的？为啥？ # 很有意思的评价，完全正确。传统运维面板是直接配置宿主机的（核心是 面板 + LAMP/LNMP 一键环境 + 文件管理 + 防火墙 + 常用组件（MySQL、Redis、FTP）），而新时代运维面板则是面向容器的（核心是：应用部署、数据库创建、备份、监控、多节点（Docker Swarm）、Git 部署、调度任务等一整套东西。Dokploy 天生就想「顺带管 ingress 和证书」，用 Traefik 做入口层。。底层是：部署容器、管理容器网络、配置 ingress/router，而不是直接改宿主机 nginx.conf。）。这个转变的核心在于：1、应用部署更复杂，尤其是CICD支持（多环境需求dev/test/prod）2、在手动运维和云服务商之间的缝隙，找到的合适生态位。

  - 【附加特性】提供什么扩展？内置监控、日志、SSL 证书和备份功能，提升管理便利性

ww:
  - 【where】Dokploy 控制平面（核心Dokploy服务）应该部署在内网 homelab 还是公网上？要确切答案 # 部署在内网（或仅 VPN/Zero Trust 可达），不要把 Dokploy 面板直接暴露公网。理由是它是运维控制面，暴露公网攻击面更大；建议对外暴露的是应用而不是面板。

  - 【内网应用】
  - 部署Dokploy需要什么配置？ # Dokploy更多是功能聚合，几乎没有多余资源开销，分核心Dokploy服务和Remote Server两方面说。核心Dokploy服务的内存开销250MB（Dokploy 自己那几个容器（Next.js + Postgres + Redis + Traefik））, 如果只是管理remote server的话，几乎没有CPU开销（CPU开销主要是build image），这就是除了本身的业务container以外，Dokploy会多出的开销。在Remote Server上则完全没有多余开销。
  - Dokploy是不是玩不了k8s这套东西？那k8s是否有类似dokploy这种PaaS运维面板？ # 玩不了（Dokploy和Coolify都是docker/swarm这套路线的，这也跟上面所说的“适用于开测环境和自建应用，无法应用于企业级生产环境”相吻合）。k8s的运维面板可以去用 kubero/Devtron/Otomi之类的。其实二者也各有各的生态位，是互补关系。正如上面所说日常开测环境和自建应用不需要k8s化，用Dokploy就很合适。那如果有真正的企业级应用在生产环境要跑，再去用kubero之类的补充这部分需求。

  - 【nix】Dokploy跟NixOS是否适配？怎么安装Dokploy能尽量避免污染宿主机环境？ # Dokploy跟NixOS完全是两套哲学。但并不意味着不能协同使用。核心在于分层（“业务类的直接用portainer托管，infra类的直接nix化”）。比如说，dokploy install shell 会尝试which docker，如果没有就安装，那么对于docker这种infra层的，我们是一定要用nix管理的。按照我目前的理解，相较于目前我在portainer的分层应用，无非是拿走了ingress层（还有DB+部署策略+监控）。除此之外，没有其他区别。

  - 4、是否需要部署多套dokploy服务（比如说我家里的homelab已经部署了dokploy，VPS上也有一些服务目前也在用compose部署，是否支持直接homelab上的dokploy直接托管这部分compose，还是VPS上也需要部署dokploy？）？
  - 7、这个是否更多用来搭建 DevContainer 或者测试环境什么的特别好用，如果是企业级生产环境就不适合了，企业级生产环境最终还是要落在云服务商那边，对吗？

hti:
  - 【方案选择】如何实现从代码到上线？选择 Applications 接 Git/GitHub/Docker 源并配置构建方式与环境变量后部署
  - 【编排落地】如何实现多服务编排？使用 Docker Compose 并配置 Traefik labels 与 dokploy-network 接入
  - 【多机架构】如何实现多服务器部署？启用 Remote Servers，将运行与流量入口放在部署服务器上分布承载
  - 【灾备实现】如何实现备份与恢复？配置 S3 目的地后定时备份，恢复时替换配置并重建数据库
htu:
  - 【Dokploy备份】
  - 【Remote Server】dokploy 里面 remote server 的 enable dashbaord，是用来干啥的？
  # 【ww】：看路由/域名到底有没有被 Traefik 接到：有哪些 routers、services、middlewares、证书解析器之类，方便排查「域名不通」「跳转不对」「证书不对」这类问题。Traefik 官方也把它定义为“集中查看当前生效路由”的面板。
  # 【htu】临时打开 → 去看 Traefik dashboard 里当前路由规则/服务状态 → 定位是域名、端口、rule、证书还是上游容器的问题 → 处理完再关掉。
  # Traefik dashboard 往往会暴露不少内部信息（路由、服务名、入口等）。如果你的 8080 端口直接公网可访问，建议 只临时开启，或至少配合 防火墙仅允许自己 IP / 走 VPN / 加认证 再用。

  - 【构建方式】Dokploy 支持哪些构建链路？可选 Docker/Nixpacks/Buildpacks 等以适配不同语言与仓库
  -
hto:
  - 【性能调优】如何减少构建时间？启用缓存和资源限制，优化 Docker 镜像大小
  - 【安全加固】如何提升防护？配置访问控制、启用 SSL 和漏洞扫描，限制端口暴露
  - 【负载优化】如何处理高流量？Scale 容器实例或集成外部监控如 Prometheus
  - 【避坑指南】常见问题如何解决？检查服务器资源不足或端口冲突，确保 Traefik 配置无误

  - 【队列治理】如何优化频繁发布带来的拥塞？控制推送频率并取消排队中的部署，避免队列堆积影响可用性
  - 【资源优化】如何降低构建对运行的影响？分离 UI 与运行节点并设置资源限制，避免构建耗尽内存/磁盘
  - 【路由优化】如何提升证书与路由稳定性？确保 DNS 正确、labels 命名唯一、网络接入一致并留足证书生成时间
  - 【安全加固】如何避免防火墙“形同虚设”？使用 ufw-docker 或云防火墙限制容器暴露端口，同时强化 SSH 安全策略
```



### what

:::tip

> ***Dokploy的核心技术栈是 docker-swarm + traefik***

:::

---


```markdown
是的，你的理解**基本正确**。

**Dokploy** 的核心基础设施确实是 **Docker Swarm + Traefik** 这两个关键组件：

- **Docker Swarm**：Dokploy 在安装时会自动初始化 Docker Swarm（即使是单节点也会进入 Swarm 模式）。它原生支持 Docker Swarm 集群，可以轻松扩展到多节点（manager + workers），并使用 `docker stack deploy` 来部署复杂的应用。Dokploy 的很多高级功能（如多服务器部署、replicas、健康检查等）都是构建在 Swarm 之上的。

- **Traefik**：作为 Dokploy 的**反向代理和负载均衡器**（reverse proxy & load balancer），负责自动服务发现（Docker Provider + Swarm Provider）、路由、TLS（Let’s Encrypt 自动证书）、HTTP/3 等。Dokploy 会自动为你的应用添加 Traefik labels（或动态配置文件），实现零配置暴露域名。

### 补充说明（让理解更完整）：
- **不是纯 standalone Docker**：虽然 Dokploy 也完美支持普通的 `docker compose`（单容器或多服务），但其底层和集群功能强烈依赖 Swarm。即使单节点部署，也推荐/默认使用 Swarm 模式。
- **Traefik 是核心入口**：所有外部流量基本都走 Traefik（80/443 端口），它会根据 labels 或动态配置自动路由到后端服务。
- 其他技术栈部分：
  - 前端/面板：Next.js + TypeScript
  - 数据库：PostgreSQL（主存配置） + Redis（队列）
  - 构建：支持 Nixpacks、Heroku Buildpacks、Dockerfile 等

总之，你说的 **“Dokploy的核心技术栈是 docker-swarm + traefik”** 抓住了它最核心、最具特色的部分 —— 这也是 Dokploy 相比一些其他自托管 PaaS（如 Coolify）在生产/集群场景下被认为更强的原因之一。

如果你在实际使用中遇到 Swarm + Traefik 的具体配置问题（比如 labels 放置、overlay network、multi-node 高可用等），可以再详细说说，我可以帮你细化。
```







### zzz

当时也尝试了 dokku,

结论是这些还不如 dokploy 好用呢





</details>

## Ref

- [Dokploy is my absolute favorite way to deploy to a VPS in 2025 - YouTube](https://www.youtube.com/watch?v=ELkPcuO5ebo&t=1124s)
- [Dokploy is the sweet spot between PaaS and EC2 | Hacker News](https://news.ycombinator.com/item?id=44884077)
- [Traefik "Enable dashboard": dokploy traefik container gone, all services domains down. [with solution] · Issue #2996 · Dokploy/dokploy](https://github.com/Dokploy/dokploy/issues/2996)
