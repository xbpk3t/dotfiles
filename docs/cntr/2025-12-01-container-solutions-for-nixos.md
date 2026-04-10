---
title: 关于NixOS的容器化方案
type: review
status: active
date: 2025-12-01
updated: 2025-12-01
unlisted: true
tags: [nix]
---

## Pre-Requirements

[NixOS Containers](https://nixos.wiki/wiki/NixOS_Containers)

https://nixos.wiki/wiki/NixOS_Containers

https://wiki.nixos.org/wiki/NixOS_Containers

https://github.com/xbpk3t/dotfiles/pull/21

```yaml
# https://github.com/nmclarty/nix/tree/main/servers/brittlehollow/containers
# ***https://github.com/greg-hellings/nixos-config*** 这个repo的k8s相关配置挺牛逼的
- url: https://github.com/aksiksi/compose2nix # https://github.com/efirestone/nix-managed-docker-compose
  record:
    - 【2025-10-04】nix生态的docker集成，就三类功能：1、【用nix来优化Dockerfile】实现Docker镜像构建过程的绝对可复现性，确保镜像内容由Nix精确锁定。（dockerTools、docker2nix） 2、【容器编排】用nix代替docker-compose（比如 Arion） 3、【Image交互与服务平台】Hocker用于解析和转换现有Docker镜像；Nixery提供按需生成镜像的在线服务。

    # [Running a docker-compose file automatically - Help - NixOS Discourse](https://discourse.nixos.org/t/running-a-docker-compose-file-automatically/24663)
    - |
      【2025-10-17】移除了目前nix社区的主流docker方案【arion】、【compose2nix】、【tazjin/nixery】、【hall/kubenix（nix定义k8s资源）】、【nix-community/nixhelm（把helm给nix化，，便于在 NixOS/flake/CI/ArgoCD 等场景里使用。查了一下整个gh上都没人用这个）】。我很同意【nix-managed-docker-compose】这个repo的README的观点，“用nix来定义container（以及类似资源）是痴心妄想”，注意这里有双重含义：
      1、【Docker本身就是容器的标准实现】“Nix 在创建可重复、文档齐全的构建方面非常出色，并且非常适合命令行工具和通用系统定义。但作为包管理器，情况就复杂得多了。在 Nix 中，包含依赖项的大型项目最终可能会使用错误的依赖项版本，很难引入项目的最新版本，而且许多项目根本就无法使用原生的 Nix 软件包。Flake 和 FlakeHub（使用语义版本控制）等项目旨在改善这种情况，但仍然远远不够全面。Self-Hosted 播客在第 139 集中就 Nix 打包现状提出了类似的看法。Nix 确实提供了一种方法来充实其生态系统并避免其中的一些问题：Docker 容器。使用 Nix 的 virtualisation.oci-containers 配置，您可以使用 Docker 或 Podman 运行 Docker 容器。这对于单个容器来说效果很好，但无法提供一种简单的方法来对容器进行分组或在容器之间定义网络，这与 Docker Compose 的功能类似（参见“为什么使用 Compose？”）。compose2nix 项目试图弥补这一缺陷，但这也增加了维护的难度。这就是 managed-docker-compose flake 的作用所在：它允许您使用标准 docker compose（或 podman compose）工具直接使用 docker-compose.yaml 文件。”。
      2、【docker在nixos常被用做“escape hatch”】container本身对于NixOS就是很好的补充（具体场景，看到reddit有个帖子，有个人的flutter应用难以在NixOS中打包，所以被迫放弃NixOS）。多插一句，container的哲学跟nixos本身就是类似的，声明式（可配置、可复用、可复现），所以container并不会破坏nixos的一致性。这里又是“手段还是目的”，始终牢记，nix只是手段而非目的，所以不要尝试把所有都“nix化”。这就离初心不一致了。

      回到本repo，之所以选择NMDC这个工具就是因为“直接用 docker-compose文件，而非用compose2nix把compose转成nix代码（或者直接写Arion代码），不够通用，因为compose就是container的标准，而nix不是。” 是更好更标准的方案。我想要的就是，像管理nixos上的 services一样管理各种docker服务，比如说我们在nixos里面做的那样，定义一套modules+hm配置，然后各种host通过自定义的import以及自定义服务启用，来控制该host是否引入指定服务。我希望container也可以实现类似效果。

      所以，相应的这里有两个拓展需求：
      1、怎么保证nixos里让某些container开机自启，而有些则默认不开启？
      2、怎么才能在多个host之间统一复用这套配置呢（无论是compose还是k8s配置YAML，都可以在各host之间复用）？用NMDC可以优雅地解决这两个需求（相较于用systemd来控制compose（正如这个nixos社区讨论的一样））。



            - |
              【2025-11-14】前几天已经把nixos上搞docker相关理顺了（很多上面的认知都是错误的）。几点认知：
              1、上面的理解有问题，Arion开始于2019年，nixos本身还不支持container的时代。后来有了官方的OCI-container，就不需要了。都是时代产物。
              2、为啥nixos container建议使用podman而非docker? 但是为啥我又使用docker而非podman?
              3、【compose2nix生成的又臭又长】compose2nix只是个cli tool，用来生成 virt.oci-container，但是 nixos container本身就支持对于container的全生命周期管理，为啥还要写一堆systemd呢？  因为 declarative container 无法覆盖所有(compose的)key，比如 network(只有default, 没有custom，当然通常也不需要), restart 这两个。

              综上，nixos的container部署就3种方案：
              正如nixos文档所说，nixos有两种container，Native Container (systemd-nspawn) 和 Declarative Container (可以使用docker, podman, LXD, libvirt等作为engine).

              1、compose.yml + systemd (compose是容器编排的通用标准，任何试图“翻译”他的工具，最终都会变成“为了声明而声明”的笑话)
              2、Declarative Container (单容器)
              3、Native Container (本质是nixos)

              这三种方案都有各自的使用场景，由轻到重，依次是：临时使用、持久化轻量使用（单个image）、复杂应用（多image）
```

# nixos-vps Docker 管理方案演进总结（2025-11）

下面总结过去两天你针对 **NixOS + Docker + ingress** 所做的重要架构调整。
采用你要求的四列表格结构：

---

## 方案演进表格

```yaml
- "方案": "**1. NixOS 原生 services + oci-containers（extra 模块每服务一个）**"
  "为什么设计该方案？": "初衷是希望像 nixpkgs 那样“全声明式”：每个服务变成 Nix module，使用 services.\* 与 virtualisation.oci-containers 完整托管生命周期，并提供同模块的 ingress。"
  "为什么对该方案做出调整？": "随着服务数量增加：大量重复模板（systemd/tmpfiles/ingress），维护成本高；并且你已有成熟 compose.yml，不想重写成 Nix。"
  "调整为什么方案": "**2. 把容器整合到 cntr/，用 oci-containers 统一管理容器。**"

- "方案": "**2. modules/nixos/cntr + oci-containers**"
  "为什么设计该方案？": "把容器模块化，拆出 cntr/，实现更清晰的结构。容器生命周期仍由 Nix 声明式管理。"
  "为什么对该方案做出调整？": "发现仍然需要大量重复 systemd 模板；许多服务本来就是 compose.yml，继续翻译重复劳动；想降低维护成本。"
  "调整为什么方案": "**3. 引入自研 compose helper（mkPodmanComposeService / mkDockerComposeService）。**"

- "方案": "**3. 自研 compose helper + sops-nix**"
  "为什么设计该方案？": "目标：写一个统一 helper 自动完成：systemd oneshot + tmpfiles + secrets 注入 + ingress 绑定，让每个服务的 default.nix 最小化（只传 composeFile）。"
  "为什么对该方案做出调整？": "helper 越写越复杂：需读取 config 触发递归、逻辑膨胀；开始考虑直接用成熟社区方案替代。"
  "调整为什么方案": "**4. 切到官方模块：nix-managed-docker-compose（NMDC）。**"

- "方案": "**4. 使用 NMDC（services.managedDockerCompose）管理所有 compose 栈**"
  "为什么设计该方案？": "优点：官方 NixOS 模块；直接 `composeFile = ./compose.yml`；systemd 自动生成；还支持 substitutions/substitutionsFromFiles 注入 secrets。"
  "为什么对该方案做出调整？": "实战踩坑：NMDC 串行处理所有 compose 项目 → 一个失败就退出；对网络不稳定/镜像拉取失败非常脆弱；与自研 helper 同样复杂甚至更差；开始反思：是否应该完全停止“声明式容器管理”。"
  "调整为什么方案": "**5. Docker 生命周期彻底解耦：Nix 只负责分发 compose.yml，容器生命周期改用 Taskfile（命令式）。**"

- "方案": "**5. 完全解耦：Nix 下发 compose.yml，容器用 Taskfile 管理**"
  "为什么设计该方案？": "新思路：1）compose.yml 仍放仓库；2）通过 home.file / environment.etc 部署到 VPS（例如 /srv/compose/\<stack>/compose.yml）；3）容器完全用 task compose:up/down 控制；Nix 不再干预容器生命周期。这样最稳定、最符合现实运维。"
  "为什么对该方案做出调整？": "剩余顾虑：① 如何设计 Taskfile；② 之前 ingress 与模块 enable 绑定，现在解耦后 ingress 如何保持声明式。"
  "调整为什么方案": "**6. ingress 继续声明式管理，容器生命周期命令式：Nix 只维护“域名 → 端口”映射。**"

- "方案": "**6. 最终方案：Ingress & Caddy 留在 Nix，Compose 生命周期交给 Taskfile**"
  "为什么设计该方案？": "Caddy 仍声明式：统一管理所有 domain → upstream。容器由 Taskfile 起/停，两者彻底 decouple。你只需保证任务启动的服务端口与 ingress 配置一致即可。"
  "为什么对该方案做出调整？": "这样避免了 declarative/imperative 混用导致的心智负担；入口层继续稳定版本化，应用层完全自由。"
  "调整为什么方案": "**当前稳定方案：Nix 管 ingress，Taskfile 管容器。**"
```

---

## review

```markdown
你觉得为啥我会绕这么一大圈？为啥没有一开始就发现最终的解决方案？我没有想清楚哪几个问题，导致这么一个不好的结果

我会觉得

Docker compose 本身应该是 declarative 而非 Imperative 的

所以既然二者都是 declarative 那么应该很好组织在一起。却忽视了既然都是声明式的，那么 docker 本身就有 container 的生命周期管理。而 nixos 则很难插足。
```

<details>
<summary>zzz</summary>

我觉得你那一大圈，本质上是「**把几个‘看起来一样’的东西混在了一起**」，而当时这几个关键问题没有被说清楚：

---

## 1. 把「配置是声明式」和「生命周期是声明式」混为一谈了

你现在自己已经点出来了核心：

> Docker compose 本身应该是 declarative 而非 Imperative 的
> …却忽视了既然都是声明式的，那么 docker 本身就有 container 的生命周期管理。而 nixos 则很难插足。

更细一点拆开：

- **Compose 的 YAML 是声明式的**：
  它描述的是「想要有这些 service、这些 volume、这些 env」。
- 但 **Docker/Compose 的生命周期管理方式是命令式的**：
  - 需要你跑 `docker compose up -d` / `down`。
  - 重启策略、拉镜像失败、healthcheck、重启容器，都是 Docker 自己那一套。

而 NixOS 的声明式是另一层：

- `configuration.nix` 描述的是「这个机器的最终状态」；
- NixOS 的 _convergence_ 由 `switch` / `systemd` 保证。

于是你无形中做了这件事：

> **用一个“声明式系统（Nix）”去包裹另一个“自带生命周期的声明式系统（Compose + Docker）”。**

这就等于搞了“两套控制平面同时想管同一批容器”：

- Docker：我认为 container 生命周期是由 `docker compose` 决定的；
- Nix：我认为 container 生命周期是由 `enable = true/false` 决定的。

两套都「声明式」，**但宣称的“真相”不一样**，于是各种别扭全出来了：
删掉 Nix 配置容器还在，NMDC 一个栈失败全家停，健康检查挂掉导致 colmena 失败等等。

---

## 2. 一开始没把「谁是 Owner」这个问题说死

你一开始的思路更像是：

> “既然都声明式，那就让 Nix 统一当 orchestrator，把 Docker 当 runtime。”

但下面几个问题当时没有被写死：

### 1. **容器的“生死权”到底归谁？**

- Nix 是不是有权利在你没说话的时候，把某个栈 down 掉？
- 你在 VPS 上手动 `docker compose up -d`，Nix 看到“配置里没这个服务”，到底要不要把它清掉？

### 2. **失败隔离要到什么粒度？**

- 你后来是明确不爽 NMDC 的：一个 qinglong 拉镜像超时 → 整个 managed-docker-compose 躺平。
- 这其实就是：你默认想要的是「每个栈独立失败」，但没有在设计之初写成硬要求。

### 3. **运维姿势到底是「Nix 优先」还是「Docker 优先」？**

- 如果真的是 Nix 优先，那就要接受「所有 up/down 都必须通过 Nix」；
- 但你很明显更习惯「我 ssh 上去 docker ps / docker compose debug」。

这几个问题没先说清楚，就很自然地一直在尝试各种「折中的统一方案」：自研 helper → NMDC → compose2nix…
直到你意识到：**我其实想要的是“各管各的”：Nix 管系统和 ingress，Docker 自己管容器。**

---

## 3. 把问题当成「如何抽象」而不是先问「要不要抽象」

你中间花了不少精力在：

- 写 `mkPodmanComposeService` / `mkDockerComposeService`；
- 想用 helper 把 systemd / tmpfiles / sops / ingress 全通吃；
- 再往上套 NMDC，希望 “一个模块统管所有 compose”。

这背后的前提其实是：

> 「我们肯定要用 Nix 来托管容器生命周期，只是还没找到最优抽象。」

但现在回头看，你最后满意的方案反而是：

> 「容器生命周期**不要**用 Nix 托管。」

也就是说，**真正要问的问题不是“怎么抽象得优雅”，而是“这个东西需不需要被抽象到这一层”**。

如果一开始就把这句写在纸上：

- “这些 Docker 服务是**玩具 / 辅助工具**，我要随时 ssh 上去 docker compose up/down；
- 不追求 roll-back、代数语义、版本 pin；
- 只希望 compose.yml 跟系统配置在一个 repo 里，不希望 Nix 改我容器的生死。”

那其实你一开始就会直接走到现在这套：

> Nix **只分发文件** → Taskfile / docker compose **管生命周期** → Caddy ingress **单独声明式**。

---

## 4. 把「声明式配置」和「声明式收敛」混在了一起

更理论一点：

- **Docker compose：**
  配置是声明式的，但没有“自动收敛”的引擎，需要你手动触发 up/down，
  也没有全局 fixed-point：你可以随时 `docker exec` 改东西。

- **NixOS：**
  配置是声明式的，有一个明确的 “激活动作”（`switch`），
  而 systemd 又是一套自己的收敛系统（服务重启、依赖、target）。

你试图：

> 用一个 declarative engine（Nix+systemd）
> 去 wrap 另一个 declarative engine（compose+Docker），
> 但两个 engine 都以为自己是那个“真理来源”。

在这种多层 declarative 的模型里，非常容易出现你这次踩到的坑：

- 谁负责 rollback？
- 谁负责监控 health？
- 谁有权认为「某个 service 已经不存在」？
- 当网络抖动 / registry 超时时，是整个 declarative run 失败，还是跳过某几个 service？

这些问题，只有在你**分层**以后才好回答：

- 层 1：系统 & ingress → Nix 管；
- 层 2：容器进程 → Docker/Taskfile 管；
- 层 3：应用配置 → 各 app 自己的方式。

你最后的方案，其实就是**把层划清楚了**。

---

## 5. 那么总结一下：你真正「没想清楚」的是哪几件事？

我用你的视角帮你列一下复盘结论：

1. **没先写清「谁是 container lifecycle 的单一 Owner」。**
   默认以为 “既然都是 declarative，大家可以和谐共存”，结果变成双管齐下、谁都说了不算。
2. **把「declarative config」当成了「declarative orchestration」。**
   compose.yml 可以 declarative 地描述服务，但 orchestrator 只有一个，要么是 Docker，要么是 Nix，混用就乱。
3. **一开始就假定“容器必须被 Nix lifecycle 管理”，而不是把它当作一个可以完全命令式的层。**
   实际上你对这些服务的期望更接近「方便调试 / 随时起合」，而不是 “整台机器必须 roll-back 到某个配置快照”。
4. **没有把“失败隔离粒度”和“网络不稳定”放在一开始的约束里。**
   所以 NMDC 那种 “一个 compose 项挂掉整个脚本报错” 行为，在你的真实需求下面是完全不能接受的。

---

要安慰一句的话：
你绕的这一大圈，其实让你把 **NixOS 声明式 vs Docker 声明式** 之间的鸿沟踩得非常透。
以后你再设计任何 “双 declarative 系统叠加” 的东西（比如 Terraform + K8s、K8s + Helm + ArgoCD、Nix + k3s），脑子里应该都会自动弹出几个问题：

- 谁是 lifecycle owner？
- 谁负责 rollback？
- 谁能删资源？
- 谁能认为「这个东西不存在了」？

这些问题一旦先写在纸上，你就不会再踩同一类坑了。

</details>

## 正确的决策流程

```markdown
那你能回答

谁负责 rollback？
谁负责监控 health？
谁有权认为「某个 service 已经不存在」？
当网络抖动 / registry 超时时，是整个 declarative run 失败，还是跳过某几个 service？

这几个问题吗？

为啥需要想清楚这几个问题才能避免踩坑？

以及下次我如果遇到了类似问题，正确的思考角度和思考路径 应该是什么？也就是具体应该怎么做决策？
```

<details>
<summary>zzz</summary>

## 1. 在你“最终方案”里，这四个问题的答案是啥？

当前架构简述：

- **NixOS**：负责系统 + Caddy + ingress（域名 → 端口）
- **Docker compose + Taskfile**：负责容器生命周期（up/down/restart）
- **compose.yml**：放在仓库里，通过 Nix 分发到 VPS 某个目录

---

### 1.1 谁负责 rollback？

按层拆开：

```yaml
- "层级": "系统 & ingress（NixOS + Caddy）"
  "谁负责 rollback？": "**Nix**"
  "怎么做": "用 `nixos-rebuild switch --rollback` 回到上一代；Caddy 配置一起回滚。"

- "层级": "容器 & 应用（docker compose）"
  "谁负责 rollback？": "**Git + 你自己**"
  "怎么做": "`git checkout` 回到旧版 compose.yml，然后执行 `task compose:up`（或类似命令）重新起容器。"
```

关键点：
**Nix 不再负责容器 rollback**，容器只和 `compose.yml` 的 Git 历史 + 你的命令有关。

---

### 1.2 谁负责监控 health？

```yaml
- "层级": "系统 & ingress"
  "谁负责 health？": "systemd + Caddy"
  "你的语义": "Nix 只确保 Caddy 这个 service 活着；Caddy 如果 upstream 不通就返回 502/504，但不会让 Nix 部署失败。"

- "层级": "容器 & 应用"
  "谁负责 health？": "Docker 自己 + 你"
  "你的语义": "`docker compose` 按 `restart`、`healthcheck` 等规则处理；Taskfile 只是触发 up/down，Nix 不关心容器健康。"
```

如果未来加 Prometheus/Alertmanager，它们属于“观测层”，只观察，不操纵 Nix rollback。

---

### 1.3 谁有权认为「某个 service 已经不存在」？

区分 ingress & 容器：

```yaml
- "对象": "某个域名 ingress（Caddy route）"
  "谁有“语义上的发言权”？": "**Nix 配置**"
  "语义": "如果 Nix 配置中删除了这个 ingress，下次 `switch` 后它就应当在 Caddy 配置中消失，从系统视角“它不该存在”。"

- "对象": "某个 docker compose 栈 / 容器"
  "谁有“语义上的发言权”？": "**Taskfile + compose.yml + 你的操作**"
  "语义": "如果不再需要某个栈：删掉 repo 中对应目录/Task，执行一次 `docker compose down`，之后 Nix 重建系统也不会“帮你复活”这个栈。"
```

一句话总结：
**入口层存在性由 Nix 决定，容器层存在性由 Docker/你自己决定。**

---

### 1.4 网络抖动 / registry 超时时，怎么办？

你当前架构下，这个问题已经“拆层”了：

```yaml
- "场景": "`nixos-rebuild switch` 时网络问题"
  "谁在跑": "NixOS 下载 / eval"
  "行为": "只影响 Nix 包/通道，不会尝试拉容器镜像，因此不会因为某个镜像拉不下来而导致整次系统部署失败。"

- "场景": "执行 `task compose:up` 时镜像拉不下来"
  "谁在跑": "Taskfile + `docker compose`"
  "行为": "只影响当前栈 / 当前命令。可以让它直接 fail 然后你手动重试，也可以在 Taskfile 里自定义“失败策略”。对 Nix 完全无影响。"
```

因此在这套方案里：

> 网络抖动 / registry 超时时，
> **不会让 Nix 的 declarative run 整体失败**，
> 只影响当前 docker 命令；
> “跳过/重试/硬失败”由 Taskfile/你自己决定。

---

## 2. 为啥这四个问题想不清楚，就容易踩坑？

这四个问题分别踩四类典型雷：

### 2.1 “谁负责 rollback？”

没说清会出现：

- Nix 回滚到旧配置，但 Docker 还跑着新版本容器 → ingress 指向旧预期，新容器在跑，状态极其诡异。
- 或者你 docker 回滚了镜像版本，但 Nix/NMDC 下一次又把你推回新版本。

结果就是：

> **你不知道“回到昨天”到底以谁为准。**

debug 永远半天云雾。

---

### 2.2 “谁负责监控 health？”

没说清容易变成：

- 把“health check 失败”当成“整个 declarative run 失败”，
  一个 qinglong 镜像拉超时，就把全机 deploy 拖死。
- 或者在错误的层调试：以为 systemd 控 health，实际是 Docker 重启策略在生效；
  你在 Nix 改半天，问题根本不在这层。

本质问题：

> **没分清谁是“观测者”，谁是“指挥者”。**
> 把本该只是告警/监控的东西，绑到了“必须 100% 成功的激活流程”里。

---

### 2.3 “谁有权说‘这个 service 不该存在’？”

没说清会导致：

- 两套控制平面都觉得有权删：
  - Nix 认为“配置里没写，就该删”，
  - 你手动 `docker compose up` 起了同名栈，
  - 下一次 Nix 觉得“这是脏东西”给你删掉。
- 反之，谁都不敢删：
  一堆“声明里不再有、但还在跑”的幽灵容器，谁也不确定能不能直接 `rm`。

长久下来：

> **系统实际状态和声明文件完全对不上号，变成“考古工程”。**

---

### 2.4 “网络抖动 / registry 超时要不要 all-or-nothing？”

没想清楚时，最容易做的蠢事就是：

> 把“拉镜像”这种高波动、易失败的操作，
> 绑到 “必须全成功才能算完成” 的 declarative run 里。

这几乎注定：

- 一点网络不稳定 / registry 抽风，就导致“整次 deploy 失败”；
- 明明系统配置没问题，只是某个镜像暂时拉不到，就卡在那不前进。

你对 NMDC 的不满，本质就是这一点。

---

## 3. 下次遇到类似问题，正确的思考角度和决策路径

给你一个可复用的“小决策模板”。

### 3.1 第一步：先画“层”，不要先想抽象

先把这次涉及的东西分层，例如：

- 层 1：OS / 基础系统（NixOS）
- 层 2：运行时（Docker / k3s / Podman）
- 层 3：工作负载（compose.yml / Helm chart / K8s manifest）
- 层 4：入口（Caddy / Nginx / Ingress）
- 层 5：运维自动化（Taskfile / CI / ArgoCD / Flux）

**只画层，不急着想“怎么优雅封装”。**

---

### 3.2 第二步：每一层强行回答 6 个问题

建议你以后新搞一个组合，就新建个 `docs/arch/<stack>-lifecycle.md`，用下面这 6 个问题当章节标题写清楚：

```markdown
1. **谁是 lifecycle owner？**

- 这层资源的创建/销毁/重建 **由谁决定**？

2. **谁是 source of truth？**

- 期望状态写在哪？Nix？Terraform？Git 仓库？某个 UI？

3. **谁负责 rollback？**

- 真要“回到昨天”，你是回哪个东西的版本？

4. **谁有权删资源？**

- 哪个系统/流程删了东西，算“合理”，不会被其他系统自动打脸重建？

5. **谁有权认为“这个东西不该存在了”？**

- 从设计语义上，它不在声明里就意味着“必须消失”吗？是谁负责做这个判断？

6. **遇到外部不稳定（网络/registry/API），这层是否 all-or-nothing？**

- 是否允许“部分失败”？失败策略是“重试/跳过/告警”，还是直接“整次 run 失败”？
```

这 6 个问题，基本能把所有“多 declarative 系统叠加”的坑提前暴露出来。

---

### 3.3 第三步：用“真实运维姿势”校验设计

问自己几件非常现实的问题：

- **我日常 debug 最顺手的是啥？**
  - 如果 80% 情况下是 `docker ps` / `kubectl get pods`，
    说明运行时那层应该偏命令式，而不是让 Nix/TF 当绝对主人。
- **这些东西有多“严肃”？**
  - 真正需要强一致 + rollback 的，通常是底层 infra / OS / ingress；
  - 玩具、辅助工具、临时服务可以容忍“只靠 Git + 命令行”。
- **我能接受的失败模式是什么？**
  - 有些层可以接受“一失败就全 fail”（比如系统引导）；
  - 有些层适合“失败就算了，下次再拉”（比如某个非核心工具容器）。

然后据此做决策，例如：

- 容器层：**命令式 + Git 版本即可，不进入 Nix lifecycle**；
- ingress 层：重要、需要版本化 → **放进 Nix，享受 generation + rollback**。

---

### 3.4 第四步：写成“宪法”，固定下来

像这样写在 repo 里（示例）：

```markdown
# Nix + Taskfile + Docker + Caddy Lifecycle 约定

- Nix 只管理：
  - 系统包 / 用户 / systemd services（包括 Caddy）
  - Caddy ingress 路由（域名 -> 端口）

- Docker 容器生命周期：
  - 仅通过 Taskfile / `docker compose up/down` 控制
  - Nix 不自动创建/删除容器，不拉镜像

- Rollback：
  - 系统和 ingress：用 Nix generation rollback
  - 容器与应用版本：用 Git revert 对应目录，然后重新执行 Task

- 外部不稳定（网络 / registry）：
  - Nix deploy 不负责拉镜像，不因镜像失败而失败
  - `docker compose` 拉镜像失败只影响当前命令，不影响其他层
```

以后你如果又想写个“超优雅的 Nix 容器 helper”，
先翻这份“宪法”看一眼：

> “Nix 不自动创建/删除容器，不拉镜像”

你就会非常清楚：
要么你准备修改宪法（真的有充分理由），
要么就按宪法办事，收一收抽象冲动。

</details>

## 拓展

```markdown
那么能否告诉我上面你说的这几个

Terraform + K8s、K8s + Helm + ArgoCD、Nix + k3s

各自来说一下

谁是 lifecycle owner？

谁负责 rollback？

谁能删资源？

谁能认为「这个东西不存在了」？

这几个问题

同样给我画个table

---

注意给我 md 格式
```

<details>
<summary>zzz</summary>

# 多层「声明式系统」的职责划分对比

下表假设的是**比较健康/常见的架构用法**（不是唯一正确，但是在实践中比较少踩坑的那种）。

```yaml
- "Stack 组合": "**Terraform + Kubernetes**"
  "谁是 lifecycle owner？（谁主导“活着/挂掉/重建”的过程）": "**Terraform 负责云基础设施生命周期**（VPC、节点、LB、RDS…）**Kubernetes 负责 Pod/Service 生命周期**（调度、重启、水平伸缩）"
  "谁负责 rollback？（按“版本/快照”回到之前状态）": "基础设施层：**Terraform rollback / state 操作**（例如切回上一个 apply 的 plan 或用 git + state 管理）集群内工作负载：通常依赖 **GitOps/Helm/手动 kubectl apply 的版本**，Terraform 不负责 Pod 级别 rollback。"
  "谁能删资源？（“可以/应该”删，而不是“技术上能不能”）": "**Terraform “应该”删 infra 资源**：它管理的那一层（节点组、LB、DNS、Bucket…）应该只通过 `terraform apply`/`destroy` 改动。Kubernetes 控制器删的是集群内对象（Deployment/Pod/Service），不直接动云资源。"
  "谁能认为「这个东西不存在了」？（在语义上有权说：这个对象不该再存在）": "在 infra 层：**Terraform 拥有解释权**——state 里没有的资源，长期而言应该被视为“流浪资源”。在集群层：**Kubernetes (加上你选的 GitOps/Helm) 拥有解释权**——manifest 里没有的对象应被认为是“脏东西”，迟早要清掉。"

- "Stack 组合": "**Kubernetes + Helm + ArgoCD**"
  "谁是 lifecycle owner？（谁主导“活着/挂掉/重建”的过程）": "推荐做法：**ArgoCD 是 lifecycle owner**（Git 里怎么写，集群就长成什么样）。Helm 只是模板引擎和打包工具；Kubernetes 是 runtime，负责实际运行与重启。"
  "谁负责 rollback？（按“版本/快照”回到之前状态）": "**ArgoCD 负责 rollback**：回滚到 Git 的某个 commit 或某个 Application Revision。Helm 在这种架构下不再单独对线上集群做 `helm upgrade --install`，而是由 ArgoCD 调用。"
  "谁能删资源？（“可以/应该”删，而不是“技术上能不能”）": "Git 里的 manifest + ArgoCD 决定“该不该存在”。**ArgoCD 可以删 K8s 资源**（把它从 Git 中删掉，ArgoCD 会同步删除）；**Helm CLI 不再直接删线上资源**，否则会和 Argo 冲突。"
  "谁能认为「这个东西不存在了」？（在语义上有权说：这个对象不该再存在）": "**Git（即 ArgoCD 的源）说了算**：Git 里不再存在的 Deployment/Service，理论上就不应该存在于集群里；ArgoCD 的 “Prune” 动作就是在执行“这些不在声明里的东西要被视为不存在并删掉”。"

- "Stack 组合": "**Nix + k3s（或 Nix + 任意 Kubernetes）**"
  "谁是 lifecycle owner？（谁主导“活着/挂掉/重建”的过程）": "如果你用 Nix 只安装 k3s（二进制、服务），而 **工作负载由 GitOps/Helm 管**：→ **Nix 仅是“集群 runtime 的 lifecycle owner”**（启动/升级 k3s），不管业务 Pod。如果你用 Nix 生成 K8s manifest 并直接 kubectl apply：→ 那一层上 **Nix + Git 变成 workload 的 lifecycle owner**。"
  "谁负责 rollback？（按“版本/快照”回到之前状态）": "系统层：**Nix rollback**（`nixos-rebuild switch --rollback`）负责 k3s 版本、系统 daemon 状态回滚。集群工作负载：看你选什么：– 如果 GitOps（ArgoCD/Flux），rollback 由 GitOps 工具 + Git 负责；– 如果 Nix 直接产 manifest 并 apply，rollback 实际上是 “回退 Nix 配置 + 重新 apply”。"
  "谁能删资源？（“可以/应该”删，而不是“技术上能不能”）": "系统层：**Nix 可以删/改 k3s 自身**（版本、服务、启动方式），但一般不直接删 Pod。集群内：– 如使用 GitOps：**GitOps 工具删资源**；– 如用 Nix 直接 apply：**Nix 的配置说删，kubectl 照做**。手动 `kubectl delete` 技术上能做，但会被下一次 apply/GitOps 恢复。"
  "谁能认为「这个东西不存在了」？（在语义上有权说：这个对象不该再存在）": "系统层：Nix 可以认为 “本机不应该再跑一个 k3s server 了”，于是移除 service；工作负载层：– 用 GitOps：**Git 仓库是“真相来源”**，仓库删掉的对象应视为不存在；– 用 Nix 生成 manifest：**Nix 配置是“真相来源”**，配置里没了就应该认定这东西不存在（即使你手动 kubectl apply 过，它也是脏状态）。"
```

---

如果你愿意，我们可以用这套四个问题反过来审视你现在的最终方案：

> Nix + Taskfile + Docker + Caddy

一起把「谁是 owner / 谁能删 / 谁能说不存在」写成一小段规范，直接贴到 `docs/arch/docker-lifecycle.md` 里，当成以后所有新东西的“宪法”。

</details>

```nix
{lib, ...}: let
  upstream = port: "http://127.0.0.1:${toString port}";
  mkProxy = port: {
    locations."/" = {
      proxyPass = upstream port;
      proxyWebsockets = true;
    };
    # TLS is handled by Cloudflare, so keep origin HTTP only.
    forceSSL = false;
  };
in {
  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    virtualHosts = {
      "beszel.lucc.dev" = mkProxy 8090;
      "rsshub.lucc.dev" = mkProxy 1200;
      "pan.lucc.dev" = mkProxy 5244;
      "ntfy.lucc.dev" = mkProxy 8020;
      "pt.lucc.dev" = mkProxy 9443;

      # "rss.lucc.dev" = mkProxy 5254;
      # "uptime.lucc.dev" = mkProxy 3001;
    };
  };

  networking.firewall.allowedTCPPorts = lib.mkAfter [80 443];
}

```

---

这里需要写一下

两种思路的区别，本质上是 xxx 实际上仍然是“边界问题”。真正的大型系统，应该用 quadlet

[SEIAROTg/quadlet-nix: Manages Podman containers and networks on NixOS via Quadlet](https://github.com/SEIAROTg/quadlet-nix)
