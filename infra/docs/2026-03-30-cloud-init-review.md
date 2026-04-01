---
title: cloud-init 初探 review
date: 2026-03-30
---


## TLDR

- `cloud-init` 不是长期配置管理系统，而是云主机 first boot 阶段的初始化执行器。
- 对你当前这个仓库来说，它最适合放在 `infra/` 里做“非 NixOS VPS 的 bootstrap”，而不是替代 Nix/NixOS。
- 第一版不需要抽象成跨云框架；一份能直接喂给阿里云 ECS `user_data` 的 `#cloud-config` 模板就已经够用。
- 当前仓库里已经新增了一份极简模板：[infra/cloud-init/aliyun-vps.yaml](/Users/luck/Desktop/dotfiles/infra/cloud-init/aliyun-vps.yaml)。

## 0. 这次 review 的边界

这篇 review 只讨论一个很具体的问题：

在你的 `infra/` 体系里，`cloud-init` 应该被理解成什么，适合解决什么问题，以及第一版应该如何落地。

这里不展开：

- 多云统一抽象框架
- 完整 Terraform ECS stack
- `cloud-init` 与 `nixos-anywhere` 的组合部署
- 复杂网络、磁盘分区、镜像构建流水线

当前边界很清楚：先把它当成阿里云非 NixOS VPS 的极简初始化能力。

## 1. 为什么现在值得看 cloud-init

你当前已经在 `infra/` 里开始形成一套比较明确的分层：

- `infra/stacks/` 负责资源层
- `hosts/` 与 `modules/` 负责 Nix/NixOS 主机内部状态

但在“普通 Ubuntu/Debian VPS 的 first boot 初始化”这一段，中间仍然缺一层足够轻的 bootstrap 手段。

`cloud-init` 正好填这个空位：

- 它不要求你先切到 NixOS
- 它几乎是公有云 Linux 镜像的事实标准
- 它比手工 SSH 进去敲命令更稳定、可复用、可审计
- 它很适合作为 Terraform 创建实例后的实例内初始化入口

换句话说，`cloud-init` 解决的不是“长期配置管理”，而是“实例刚创建出来时，如何把它拉到一个可用基线状态”。

## 2. cloud-init 的 3W3H

下面按你给的结构来讲，但不强行把每一部分压成单个问题，而是把常见关键问题拆开说。

### 2.1 Why

#### 为什么不是直接手工 SSH 上去改

因为手工初始化最大的问题不是“麻烦”，而是不可重复。

同样一台 VPS，今天你手工装了几个包、改了哪些 SSH 选项、有没有创建额外用户，过一周往往已经说不清了。`cloud-init` 把这些首启动作收束成一份可读的声明式输入。

#### 为什么不是直接上 Ansible / Nix

可以上，但那是下一层。

如果实例刚创建出来，连基础用户、公钥、hostname、最小包集都还没准备好，那么你通常还是需要一个 first boot 入口把这台机器先拉到“可以继续管理”的状态。`cloud-init` 很适合做这一层。

#### 为什么对阿里云 VPS 场景特别合适

因为阿里云 ECS 的很多常见 Linux 公共镜像本来就支持 `user_data` / `cloud-init`。这意味着你不需要引入额外 agent，也不需要先准备一套更重的配置系统，就能把 SSH key、用户和基础包安装一起做掉。

### 2.2 What

#### 它到底是什么

`cloud-init` 本质上是一个在实例启动早期执行的 initialization engine。

它会读取云平台提供的 metadata / user-data，然后按固定阶段执行对应模块，比如：

- 设置 hostname
- 创建用户
- 注入 SSH public key
- 安装 packages
- 写入文件
- 执行 `runcmd`

#### 它不是什么

它不是：

- 全生命周期配置管理系统
- 长期 drift 校正系统
- 完整的镜像构建系统
- NixOS 那种“整个系统声明式收敛”的替代品

如果把它看得太重，最后通常会把大量业务脚本、部署逻辑、应用启动流程都堆进 `runcmd`，然后在排障时非常痛苦。

#### 它在你的仓库里应该扮演什么角色

它更像 `infra/` 里的一个 bootstrap asset。

也就是说：

- Terraform 以后如果创建 ECS，可以把这份 YAML 作为 `user_data` 传进去
- 如果不用 Terraform，阿里云控制台也可以直接粘这份配置
- 机器启动后先到一个“安全、可登录、带最小工具集”的基线状态

### 2.3 When / Where

#### 什么时候适合用

下面这些场景都适合：

- 新建 VPS 时，希望自动注入 SSH key
- 不想启用密码登录
- 想统一创建管理用户
- 想在 first boot 时安装少量常用工具
- 想给实例打一个明确的 hostname / motd / 标识文件

#### 什么时候不适合继续扩

如果你的需求开始变成下面这样，就不该继续把逻辑堆在 `cloud-init` 里：

- 应用部署流程越来越长
- 需要幂等的复杂状态收敛
- 要管理几十台机器的一致性
- 要有更强的回滚与 diff 能力

这时更合适的做法通常是：

- `cloud-init` 只做 bootstrap
- 后续交给 Ansible、Nix、Salt、Chef 之类的长期配置层

#### 应该放在哪里

对这个仓库来说，放在 `infra/cloud-init/` 是合理的：

- 它不属于 `hosts/`，因为你明确说了这不是 NixOS 主机定义
- 它也还不属于某个具体 `stack/`，因为你现在只需要模板资产
- 后续真要接 Terraform ECS stack，再从这里复用即可

## 3. How to use

### 3.1 最小使用流程

当前最短路径其实很简单：

1. 打开 [infra/cloud-init/aliyun-vps.yaml](/Users/luck/Desktop/dotfiles/infra/cloud-init/aliyun-vps.yaml)
2. 替换里面的占位符
3. 在阿里云 ECS 创建实例时，把内容作为 `user_data` 提交
4. 等实例首次启动完成
5. 用注入过的 SSH public key 登录

你至少要替换两个地方：

- `REPLACE_WITH_HOSTNAME`
- `REPLACE_WITH_YOUR_SSH_PUBLIC_KEY`

### 3.2 当前模板做了什么

这份模板目前只做了最常见、最稳的几件事：

- 设置 `hostname` / `fqdn`
- 设置 `timezone`
- 执行 `package_update` 和 `package_upgrade`
- 安装 `curl`、`git`、`htop`、`tmux`、`vim`
- 创建 `deploy` 用户
- 禁用 SSH password auth
- 禁用直接 root 登录
- 写一个简单的 `/etc/motd`
- 跑两条轻量 `runcmd` 作为 bootstrap 校验

### 3.3 怎么验证它真的执行了

至少看三类东西：

1. 登录验证

```bash
ssh deploy@your-server
```

如果能用你注入的 key 登录，说明 `users` 和 `ssh_authorized_keys` 至少大概率成功了。

2. cloud-init 日志

```bash
sudo tail -n 100 /var/log/cloud-init.log
sudo tail -n 100 /var/log/cloud-init-output.log
```

3. 结果验证

```bash
hostnamectl
id deploy
cat /etc/motd
```

## 4. How to implement

### 4.1 第一版应该怎么实现

第一版实现原则应该非常克制：

- 先写一个静态 `#cloud-config` 模板
- 不先做复杂变量系统
- 不先做多云抽象
- 不先做 multipart MIME
- 不先把应用部署脚本塞进去

这次新增的 [infra/cloud-init/aliyun-vps.yaml](/Users/luck/Desktop/dotfiles/infra/cloud-init/aliyun-vps.yaml) 基本就是按这个原则写的。

### 4.2 如果后面接 Terraform，怎么接

后面如果你在 `infra/stacks/vps/aliyun/...` 里加 ECS stack，最自然的接法是：

- Terraform 管 ECS、VPC、安全组、EIP 之类的资源
- `cloud-init` 文件仍然单独维护
- ECS resource 通过 `user_data` 读取这份 YAML

也就是说，先把 YAML 当成独立资产，后面再决定它的投递方式，而不是一开始就把模板绑死在某个 provider 实现里。

### 4.3 当前模板里几个重要配置项怎么理解

#### `package_upgrade: true`

好处是首启后系统更完整，安全更新也更及时。

风险是：

- first boot 时间会更长
- 某些镜像会在升级内核后提示重启
- 如果后面你更重视“实例尽快 ready”，可能要把它改成只做 `package_update`

#### `lock_passwd: true`

这个配置配合 `ssh_authorized_keys`，意味着 `deploy` 用户默认走 SSH public key，不给密码登录留入口。

这是当前最合理的默认值。

#### `ssh_pwauth: false`

这是很重要的收敛项。

它会直接关闭 SSH password auth。前提是你已经确认公钥正确，否则你可能把自己锁在门外。

#### `runcmd`

这里最容易被滥用。

经验上，`runcmd` 适合：

- 少量、轻量、一次性的 bootstrap 动作

不适合：

- 大段部署脚本
- 复杂条件分支
- 多阶段应用发布逻辑

## 5. How to optimize

### 5.1 先优化边界，不是先优化技巧

`cloud-init` 最常见的问题不是“性能不够”，而是职责失控。

优化的第一步不是去研究各种模块细节，而是先守住边界：

- 只做 first boot
- 只做最小基线
- 不承载长期配置管理

### 5.2 再优化启动速度和失败面

如果后续你觉得首启慢、失败点多，优先从下面几个方向减法：

- 减少 `packages`
- 评估是否保留 `package_upgrade`
- 缩短 `runcmd`
- 避免远程下载过长脚本再执行

### 5.3 最后再优化复用方式

等你真的出现第二台、第三台、第四台阿里云 VPS，并且它们的初始化逻辑高度相似时，再考虑做下一层优化：

- 把 hostname、用户名、公钥改成模板变量
- 接入 Terraform `templatefile()`
- 或者再往上抽一个很薄的 cloud-init 渲染层

注意，这个优化点成立的前提是“已经重复出现了”，而不是现在先预支抽象。

## 6. 当前结论

对你现在这个仓库，`cloud-init` 的最佳定位可以压缩成一句话：

`cloud-init` 负责非 NixOS VPS 的 first boot bootstrap，Nix/NixOS 继续负责你真正长期维护的声明式系统层。

所以当前最合适的落法不是“大框架”，而是：

- 先有一份简单、可读、能直接用的阿里云 VPS 模板
- 以后如果真的开始创建 ECS 资源，再把它接进 `infra/stacks/`

这条路线和你当前仓库的组织方式是一致的，也不会把 `infra/` 过早推向过度设计。

## 7. 3W3H 技术选型 YAML

```yaml
why:
  - "【减少手工初始化】为什么要用 cloud-init？因为它能把 hostname、用户、SSH public key、基础包安装这些 first boot 动作固化成可重复输入，减少手工 SSH 初始化带来的漂移。"
  - "【适合云主机场景】为什么它在 VPS 上很常见？因为大多数云厂商的 Linux 公共镜像都原生支持 cloud-init，开箱就能消费 user-data。"
  - "【补足 bootstrap 空位】为什么不是直接上 Ansible 或 Nix？因为在机器刚创建出来时，往往还需要一层最小 bootstrap 先把实例拉到可继续管理的状态。"
  - "【与长期配置分层】为什么值得单独保留？因为它适合解决 first boot 问题，而不必把长期配置管理、应用部署、系统收敛都压进同一层。"
what:
  - "【核心定位】cloud-init 是什么？它是实例启动早期读取 metadata 和 user-data，并执行初始化模块的 initialization engine。"
  - "【常见能力】cloud-init 能做什么？它通常负责设置 hostname、创建用户、注入 SSH public key、安装 packages、写文件和执行少量 runcmd。"
  - "【能力边界】cloud-init 不是什么？它不是长期 drift 管理系统，也不是 NixOS 那种完整声明式系统。"
  - "【仓库角色】它在当前仓库里算什么？它更适合作为 `infra/` 下的 bootstrap asset，而不是 `hosts/` 里的系统定义。"
ww:
  - "【适用时机】什么时候适合用 cloud-init？当你在新建阿里云 ECS 或其他 VPS，并希望 first boot 自动完成基础初始化时最合适。"
  - "【适用位置】应该把它放在哪里？对当前仓库而言，放在 `infra/cloud-init/` 这种独立模板目录最合理，因为它暂时还不是具体 stack。"
  - "【不宜扩张】什么时候不该继续往里堆逻辑？当需求开始涉及复杂应用部署、跨多机一致性和长期状态收敛时，就不该继续把逻辑塞进 cloud-init。"
  - "【典型场景】哪些场景最适合？单机 VPS 初始化、临时实验环境、需要统一 SSH key 和基础工具集的 first boot 场景都很适合。"
htu:
  - "【使用步骤】怎么用现有模板？复制 `infra/cloud-init/aliyun-vps.yaml`，替换 hostname 和 SSH public key，再作为阿里云 ECS 的 user_data 提交。"
  - "【验证方法】怎么确认生效？首先尝试用注入过的 key 登录 `deploy` 用户，然后查看 `/var/log/cloud-init.log` 和 `/var/log/cloud-init-output.log`。"
  - "【结果检查】还要检查什么？确认 `hostnamectl`、`id deploy`、`cat /etc/motd` 的结果与模板声明一致。"
  - "【风险前置】使用前最该注意什么？在 `ssh_pwauth: false` 的前提下，必须先确认公钥已经替换正确，否则可能把自己锁在门外。"
hti:
  - "【实现策略】第一版应该怎么实现？先维护一份静态 `#cloud-config` 模板，不急着做多云抽象、模块系统或 multipart MIME。"
  - "【与 Terraform 集成】后续怎么接到 IaC？如果以后加阿里云 ECS stack，可以让 Terraform 继续管理资源层，再通过 `user_data` 引用这份 YAML。"
  - "【职责切分】哪些内容应该放进 cloud-init？基础用户、公钥、少量 packages、少量 write_files、轻量 runcmd 适合放进去。"
  - "【职责排除】哪些内容不该放进去？复杂应用部署、长脚本、长期配置收敛和大规模多机编排不应该以 cloud-init 为主承载。"
hto:
  - "【启动速度】怎么优化 first boot？优先减少 packages、评估是否保留 `package_upgrade: true`，并尽量缩短 `runcmd`。"
  - "【安全加固】怎么提高安全性？默认关闭 SSH password auth、禁用直接 root 登录、统一走 SSH public key，是最有效的最小加固。"
  - "【可维护性】怎么避免模板失控？把 cloud-init 限定在 bootstrap 边界内，避免把应用部署和长期配置逻辑持续堆入 `runcmd`。"
  - "【复用优化】什么时候再抽象模板变量？只有当多台 ECS 重复使用同一逻辑时，再考虑通过 `templatefile()` 或更薄的渲染层做复用。"
```
