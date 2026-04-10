---
title: 关于Linux安全的Nix最佳实践
type: review
status: active
date: 2025-12-17
updated: 2025-12-17
unlisted: true
tags:
  - nixos
  - server
---

```markdown
其实从这个来说，你觉得 这种生产环境服务器调优 跟 我们日常使用的 workstation 调优

有哪些核心区别？并且需要你拓展来说

我觉得这个问题挺有意思的

注意这是一个综合性很强的问题，需要你涵盖各方面，并深入浅出地进行回答
```

```markdown
我直接用一句话先总结一下区别：

> **生产服务器的调优：为了“稳定地干活给别人用”。
> Workstation 的调优：为了“舒服地被你自己折腾”。**

然后我们从几个维度把这俩拆开讲一讲，同一件事在 server / workstation 上会有 **完全不同的取舍**。

---

## 一、目标完全不一样：SLA vs 体验

### 生产服务器的核心目标

- **稳定**：跑一年不重启都要顶得住（特别是数据库、存储、核心业务）。
- **可预测**：延迟抖动小、吞吐可预期，“平均很好”没用，“最坏情况不能太烂”才重要。
- **安全可控**：谁能上来、能干啥都要能解释清楚；出了事能审计、能回溯。
- **易于运维**：统一配置、能自动化、可以拉指标、打补丁、滚动升级。

因此调优时会问：

> “我这么调，会不会降低稳定性/可控性？”

只要答案是“有风险”，很多“爽”操作就不会做。

### Workstation 的核心目标

- **主观体验好**：开机快、窗口切换跟手、浏览器/IDE/游戏不卡。
- **灵活自由**：你想装啥、改啥、玩啥都可以，偶尔挂了重装一下也不致命。
- **功能丰富**：多媒体、蓝牙、各种驱动、各种桌面特效……一堆“非必需”东西。

调优时更常见的问题是：

> “我能不能再快一点 / 再顺手一点？”

代价是：偶尔崩一次、重启一下，你能接受。

---

## 二、安全与隔离：锁死 vs 放开一点

### 生产服务器：能关的都关，能缩的都缩

常见做法：

- 最小化安装：**不装 GUI、不装浏览器、不装 office、不装没用的服务**。
- 开放端口按需：只开放业务端口 + SSH，其它一律关掉。
- SELinux / AppArmor：
  - 有些团队会 **坚持 enforcing 模式**，配好策略。
  - 实在搞不定才会像你前面那样在集群里统一关掉（但同时要靠其它手段补强）。

- 审计 / 日志：
  - 命令历史、sudo 记录、系统日志要有，方便安全排查。

**为什么？**

因为 server 是对外暴露的，一旦被打进去就是 **公司资产、数据、用户隐私** 级别的问题，代价比你个人电脑大太多。

### Workstation：安全要平衡“可用性”

- 会装大量非必要软件：聊天、网盘、播放器、游戏、各种插件。
- 端口相对更多：局域网共享、远程桌面、启动器、自带的小服务。
- SELinux / 防火墙 有时为了方便直接关了。

通常思路是：

> “我这个机器主要是我自己在用，安全和方便之间取个平衡。”

---

## 三、CPU 与电源策略：吞吐 vs 续航/静音

### 生产服务器：稳定性能优先

- CPU governor 常设为 `performance`：
  - 不做太多频率动态调整，减少延迟抖动。

- 禁用省电特性（视场景）：
  - 比如深度 C-State、Turbo Boost、超线程（某些低延迟场景会关）。

- 对多核利用做规划：
  - 利用 cgroup / cpuset 把关键服务 pin 在固定核上，减少干扰。

服务器关心的是：

> “在高负载下，延迟和吞吐是不是稳定？”

### Workstation：能耗、温度、噪音、续航

- 笔记本/台式机会用 `ondemand` / `powersave` 之类 governor：
  - 不用时降频省电，风扇安静点，笔记本还要考虑电池。

- 有些场景（开发 / 游戏 / 渲染）会临时切成高性能，但不是 7x24 全天候。
- 不会专门 pin 核，毕竟你随时可能开个 VS Code、开个游戏、同时刷视频。

这里的主要问题是：

> “日常用起来顺滑、安静、电池不太快掉就行。”

---

## 四、内存与 Swap：稳定 vs 容忍“卡一下”

你前面提到的 k8s 调优其实就踩在这一块。

### 生产服务器的思路

- **对很多延迟敏感的服务**（数据库、k8s 节点）：
  - 经常会关闭或极度限制 swap：
    - 防止进程被悄悄换到磁盘里，突然一个请求就卡几秒。

  - 调整 `vm.swappiness`、`vm.overcommit_memory` 等，让内存行为可预测。

- 非常关心 OOM 场景：
  - 会用 cgroup 限制不同服务的内存上限。
  - 配合 OOM 监控、重启策略（比如 k8s 的 livenessProbe + restartPolicy）。

目标是：

> “宁愿服务 oom 被重启，也不要突然全部慢如蜗牛。”

### Workstation 的思路

- 一般会保留 swap，而且可能还要用来 **休眠（hibernate）**。
- 偶尔开太多 Chrome tab / IDE / 游戏，内存不够就开始疯狂换页：
  - 用户体验：卡一会儿 → 关掉几个程序 → 好了。

- 不会对某个进程那么严格：你就是“想怎么开程序就怎么开”。

所以同一条建议——“关 swap”：

- 在 **k8s 节点**：是合理的“底层调优”。
- 在 **个人笔记本**：可能导致你开太多程序直接 OOM 崩桌面，体验反而更差。

---

## 五、存储与文件系统：可靠 vs 顺手

### 生产服务器的关注点

- **可靠性**：
  - RAID / 分布式存储 / 冗余盘位，尽量不单盘裸跑。
  - 关注 SSD 写放大、TBW 寿命、控制日志量。

- **文件系统 & mount 选项**：
  - 比如 ext4/xfs，合理设置 `noatime`、`barrier` 等选项。
  - 对数据库、对象存储会更细致地优化。

- **IO 调度器**：
  - 对特定工作负载（高并发小 IO、大顺序 IO）选择合适的 scheduler。

- **备份与快照**：
  - 不能指望“坏了重装”，业务数据必须有备份策略。

### Workstation 的关注点

- 大多数人：
  - 一块盘 / 两块盘，单用户使用，默认设置足够用了。
  - 需要的主要是：快一点、安静一点、容量够大。

- 调优更多集中在：
  - 把系统和数据盘分开，方便重装系统。
  - 为了加快启动和应用打开速度，选 SSD/NVMe。
  - 也许给游戏单独一个 SSD。

同样是 “写日志很多怎么办”：

- 在服务器：要权衡“日志保留时长 vs 磁盘压力 vs 合规要求”。
- 在工作站：你可能直接改一下日志级别或干脆不管，满了再删。

---

## 六、网络栈：高并发 vs 日常访问

### 生产服务器：网络就是“业务生命线”

- 会主动调这些东西：
  - 连接数等参数：`net.core.somaxconn`、`net.ipv4.ip_local_port_range`、`net.ipv4.tcp_tw_reuse` 等。
  - 接收/发送队列：`net.core.netdev_max_backlog` 等。

- 配置多网卡、Bonding、VLAN、QoS：
  - 为了冗余、高带宽、隔离、优先级。

- 比较在意 iptables / nftables / 路由性能：
  - 如何对大规模连接、高 QPS 做好 NAT、负载均衡。

### Workstation：网络主要是“上网和局域网”

- 默认 TCP/IP 设置已经完全够用：
  - 浏览网页、拉代码、打游戏、看视频这些对网络栈要求没那么极端。

- 真要调优也更多是针对：
  - Wi-Fi 稳定性、蓝牙、热点、VPN 兼容。

- 只有少数特殊工作站（高频交易测试、网络实验室）才会像服务器那样玩得很深。

---

## 七、可观测性、日志与运维手段

### 生产服务器：全都要“可视化、可审计、可自动化”

- **监控**：CPU、内存、磁盘、网络、系统调用、业务指标统统采集：
  - Prometheus / Grafana / ELK / Loki ……

- **集中日志**：
  - 不允许只留在本机，因为机器挂了日志也要能看。

- **变更管理**：
  - Ansible / Salt / Terraform / Helm / CI/CD。
  - 一个改动要能回滚、可追踪。

调优很多时候是：

> “我怎么改 sysctl，能提高性能，但不影响监控？不影响日志采集？”

### Workstation：能用就行的监控

- 通常就是：
  - 桌面上的系统监视器 / `htop` / `iotop` / `btop`，临时看一下。

- 日志：
  - 很少有人会集中采集自己笔记本的系统日志。
  - 真出问题了才 `journalctl` 看一眼。

---

## 八、更新策略与“敢不敢折腾”

### 生产服务器：保守 + 渐进

- 系统版本、内核、Docker、k8s 等：
  - 升级前要测试、压测，有时候还要灰度。

- 不会跟最新潮：
  - 比如内核更偏向 LTS，软件版本选“社区/厂商推荐范围”。

- 配合维护窗口：
  - 约好什么时候重启、什么时候滚动升级。

### Workstation：可以用来“吃螃蟹”

- 很多人：
  - 喜欢最新的桌面环境、最新的内核、最新的驱动、最新的 IDE。

- 出问题最多是：
  - “今天有点不稳定，我回退或重装一下。”

这也导致：

> **同一套调优手法，在 server 上要考虑“未来升级/兼容性”，在 workstation 上则可以更激进。**

---

## 九、统一 vs 个性：集群节点 vs 你一个人

### 生产环境服务器

- 一大堆节点，需要 **统一基线**：
  - 同样的 OS、同样的内核参数、同样的安全策略。

- 调优结果要能复制：
  - Packer 镜像 / 云镜像 / kickstart / cloud-init / 配置管理。

- 文档化：
  - 为什么关 swap、为什么设置这个 sysctl、为什么用 IPVS，得写清楚。

### Workstation

- 每个人的用途不同：
  - 有人侧重开发、有人侧重设计、有人侧重游戏。

- 调优高度个性化：
  - 哪怕全公司发一套同样的笔记本，每个人最后的配置也完全不同。

- 你可以根据自己的感觉试错：
  - 不爽就改，改坏了就重装。

---

## 最后，用一句话再帮你“提炼”一下思路

如果以后你在脑子里区分“这是服务器调优还是工作站调优”，可以简单想：

- **服务器调优三问：**
  1. 它会不会影响稳定性 / 安全性？
  2. 它能不能规模化推广给所有节点？
  3. 它有没有可观测性、可回滚的方案？

- **Workstation 调优三问：**
  1. 我日常用起来是不是更顺手了？
  2. 出问题我能不能接受重启 / 重装？
  3. 会不会给我带来明显的麻烦（兼容性、驱动问题）？

你前面写的那套 **k8s 物理机调优脚本**，本质就是一套 **“稳定、高可控的基础运行环境”**，自然更适合生产节点，而不是你日常用来写代码、听歌、打游戏的那台机子。

如果你愿意，下次我可以跟你一起做两个版本：

- 一份：**“生产 k8s 节点调优 checklist”**
- 一份：**“开发者 Linux 工作站调优 checklist”**

对比着看会非常直观。
```

[imthenachoman/How-To-Secure-A-Linux-Server: An evolving how-to guide for securing a Linux server.](https://github.com/imthenachoman/How-To-Secure-A-Linux-Server)

https://www.youtube.com/watch?v=U9NgRShXFgk

https://www.youtube.com/watch?v=RVZuYL0aehY

# Linux Server Security Baseline Checklist（基于 `imthenachoman/How-To-Secure-A-Linux-Server`）

- 基准版本：v1.0
- 最后更新：2025-12-17
- 适用范围：通用 Linux 服务器（VPS / 裸机 / 家用 Homelab），偏“运维可落地”的 hardening + 日常审计
- 使用方式：对每一项标记 ✅已完成 / ❌未完成 / 🟨部分完成 / ⛔不适用，并记录“证据”（配置文件路径、命令输出截图、工单链接等）

---

## 你还可以参考的 Server Security 文档 / “Awesome”类资源（强烈建议纳入长期基线）

1. **NIST SP 800-123：通用服务器安全指南**（体系化讲“基线、运维、审计、持续维护”）([NIST Computer Security Resource Center][1])
2. **ANSSI GNU/Linux Hardening Guide（v2）**（非常工程化、偏“可执行配置建议”）([cyber.gouv.fr][2])
3. **CIS Benchmarks**（业界常用的“可审计基线”，适合做合规/评分）([Red Hat Customer Portal][3])
4. **Mozilla OpenSSH Guidelines**（SSH 配置权威参考之一）([infosec.mozilla.org][4])
5. **OpenSCAP + SCAP Security Guide（SSG）**（把基线变成“可自动审计/可自动修复”的机器可读规则）([open-scap.org][5])
6. **Ubuntu Security Guide（USG）**（Ubuntu 上把 CIS/审计/应用配置做成工具链，适合持续检查）([Ubuntu Documentation][6])
7. **dev-sec hardening（Ansible collection）**（把 OS/SSH/nginx 等 hardening 做成可复用自动化）([GitHub][7])
8. **The Practical Linux Hardening Guide**（社区型“大全”，覆盖面广、适合扩展项查漏补缺）([GitHub][8])
9. **NSA 网络安全通告/指南索引**（关注高价值威胁与缓解思路，适合“跟踪更新”）([nsa.gov][9])

---

## 这个 repo 的内容梳理（你给的基准来源）

该仓库核心内容集中在 `README.md`（分主题给出“Why / Goals / Steps / Notes / References”），另有：

- `nginx.md`：Nginx 安全响应头/隐藏版本信息等快速清单([GitHub][10])
- `linux-kernel-sysctl-hardening.md`：当前主要是“参考链接 + 免责声明”（并未给出可直接使用的 sysctl 键清单，且作者明确“不知道大多数设置含义，仅作参考”）([GitHub][11])

README 的主线（你后面的 checklist 也按这个结构来）大致是：

- SSH：密钥、AllowGroups、sshd_config 加固、移除弱 DH moduli、可选 2FA/MFA([GitHub][12])
- 基础：限制 sudo / su、FireJail、NTP、/proc、密码强度、自动安全更新、熵池、（争议项）“panic/duress password”([GitHub][12])
- 网络：UFW、防扫描/入侵检测（PSAD）、应用层防爆破（Fail2ban / CrowdSec）([GitHub][12])
- 审计：AIDE/ClamAV/rkhunter/chkrootkit/logwatch/ss/Lynis/OSSEC([GitHub][12])
- 危险区（Danger Zone）：GRUB 密码、禁用 root 登录、umask、清理孤儿包（还有 sysctl 的“仅参考”）([GitHub][12])
- 发送邮件告警：exim4 + Gmail smarthost、以及为防火墙/iptables 单独落日志([GitHub][12])

---

# Baseline Checklist（逐项可核对 + 最佳实践）

> 标注规则：
>
> - **MUST**：建议作为所有服务器的默认底线
> - **SHOULD**：强烈建议（视业务/风险可调整）
> - **OPTIONAL**：场景相关或取舍项（做了更好，但要评估复杂度/副作用）

---

## 0) 总体原则与资产清单（建议你纳入“长期基线”，非 repo 原文）

- [ ] **MUST：明确服务器用途、暴露面与威胁模型**（公网/内网、哪些端口对外、是否承载敏感数据）([NIST Computer Security Resource Center][1])
  - 最佳实践：把“对外服务清单（端口→服务→负责人）”“管理员入口（SSH/VPN/跳板）”“数据类型（PII/密钥/备份）”写成一页文档

- [ ] **MUST：备份与恢复演练**（不是“有备份”就够，要能恢复）([NIST Computer Security Resource Center][1])
  - 最佳实践：至少 3-2-1；每季度做一次“从零恢复”演练（含权限、服务启动顺序、DNS/证书等）

- [ ] **SHOULD：基线可审计化**（后面每条都能“自动检查/持续检查”）([open-scap.org][13])
  - 最佳实践：能用 OpenSCAP/USG/CIS 就别只靠手工；把检查结果留档

---

## 1) 访问控制与 SSH（repo 核心主线）

### 1.1 SSH 密钥（Ed25519）

- [ ] **MUST：管理员 SSH 使用 Ed25519 密钥登录，禁用弱/过时算法**([GitHub][12])
  - 最佳实践：
    - 首选 Ed25519；私钥尽量带 passphrase；使用 `ssh-agent` 缓解频繁输入（但注意 agent 转发风险）([GitHub][12])
    - 服务器端 `~/.ssh/authorized_keys` 权限与所有者正确（避免可写）

  - 验证建议：检查是否仍允许密码登录（见 1.3），并抽检每个管理员账号的 `authorized_keys`

### 1.2 用 AllowGroups 管控“谁能 SSH 进来”

- [ ] **MUST：创建专用 SSH 允许组（如 `sshusers`），仅允许该组 SSH**([GitHub][12])
  - 最佳实践：把所有需要 SSH 的账号加入该组；离职/禁用时先移出组即可
  - 验证建议：`sshd_config` 中存在 `AllowGroups sshusers`（或等价策略），且组成员符合预期

### 1.3 `sshd_config` 安全基线（强烈建议按“最小暴露面”）

- [ ] **MUST：`PermitRootLogin no`**([GitHub][12])
- [ ] **MUST：`PasswordAuthentication no`（或至少对公网入口禁用）**([GitHub][12])
- [ ] **MUST：禁用不必要转发能力**（X11/隧道/端口转发等）([GitHub][12])
- [ ] **SHOULD：限定 Kex/Ciphers/MACs 到现代安全组合**（参考 Mozilla 指南）([GitHub][12])
- [ ] **SHOULD：`LogLevel VERBOSE` 以便审计到 key fingerprint**([GitHub][12])
- [ ] **SHOULD：设置合理的暴力破解缓解参数**（如 `MaxAuthTries`、`LoginGraceTime`、`ClientAliveInterval/CountMax`、`MaxSessions` 等）([GitHub][12])
- [ ] **MUST：避免重复/冲突配置项（sshd 取“第一条”）**([GitHub][12])

建议你把 repo 给的“通用必须项”整理成你自己的基线表（示例）([GitHub][12])：

```yaml
- "类别": "身份认证"
  "设置项（示例）": "`PermitRootLogin`"
  "推荐方向": "`no`"

- "类别": "身份认证"
  "设置项（示例）": "`PasswordAuthentication`"
  "推荐方向": "`no`（优先）"

- "类别": "授权控制"
  "设置项（示例）": "`AllowGroups`"
  "推荐方向": "仅允许指定组"

- "类别": "转发能力"
  "设置项（示例）": "`X11Forwarding`"
  "推荐方向": "`no`"

- "类别": "转发能力"
  "设置项（示例）": "`AllowTcpForwarding` / `AllowAgentForwarding` / `PermitTunnel`"
  "推荐方向": "默认 `no`，确需再开"

- "类别": "加密套件"
  "设置项（示例）": "`KexAlgorithms` / `Ciphers` / `MACs`"
  "推荐方向": "按 Mozilla 现代基线"
```

### 1.4 移除弱 Diffie-Hellman moduli（< 3072 bits）

- [ ] **SHOULD：移除小于 3072 bits 的 DH moduli**([GitHub][12])
  - 最佳实践：这是 SSH 加固里常被忽略但很关键的一步；做完后重启 sshd 并验证

### 1.5 SSH 的 2FA/MFA（可选但很强）

- [ ] **SHOULD：对密码登录启用 TOTP（PAM + google-authenticator-libpam）**([GitHub][12])
  - 最佳实践：
    - 明确“哪些入口必须 2FA”（例如：公网 SSH 强制；内网跳板可选）
    - 注意 repo 提醒：默认配置下 **密钥登录可能不会触发 2FA**，如需“密钥也要 2FA”要额外设计策略([GitHub][12])

  - 风险提示：把应急 scratch codes 放入安全保险库（而不是随手记在本地）

---

## 2) 提权与本地权限控制（repo：sudo / su / umask）

### 2.1 限制 sudo 使用者范围

- [ ] **MUST：仅允许指定组的用户使用 sudo**（如专用 `sudousers`）([GitHub][12])
  - 最佳实践：
    - 严格控制 sudo 组成员；不要给不需要的人“顺手的 root”
    - 明确是否允许免密 sudo（很多发行版/云镜像会这样做，风险更高）([GitHub][12])

### 2.2 限制 su 使用者范围

- [ ] **SHOULD：限制 `/bin/su` 仅允许指定组执行**（如 `suusers`）([GitHub][12])
  - 最佳实践：让 su 变成“更少的人能用的后门”，并把日常提权都走 sudo（便于审计）

### 2.3 默认 `umask`（文件权限“默认更收敛”）

- [ ] **SHOULD：非 root 默认 `umask 0027`，root 默认 `umask 0077`**([GitHub][12])
  - 最佳实践：减少“新建文件默认可被同组/其他人读到”的概率（尤其是含密钥、配置、备份碎片时）

---

## 3) 基础系统安全（repo：NTP、/proc、密码策略、自动更新、熵池）

### 3.1 时间同步（NTP）

- [ ] **MUST：启用 NTP 客户端，确保时间可信**([GitHub][12])
  - 最佳实践：很多安全协议依赖时间（证书、TOTP、日志取证）；确保配置使用可靠的时间源池策略([GitHub][12])

### 3.2 密码强度策略（PAM + pwquality）

- [ ] **MUST：强密码策略落地（最少长度、复杂度、重复字符限制、避免用户名相关）**([GitHub][12])
  - 最佳实践：repo 示例启用 `pam_pwquality` 并给出一组较合理的参数（`minlen`、`ucredit/lcredit/dcredit/ocredit`、`difok`、`maxrepeat`、`gecoscheck` 等）([GitHub][12])
  - 验证建议：对新建用户/改密流程做一次实测

### 3.3 自动安全更新 + 通知（Debian/Ubuntu 路线）

- [ ] **MUST：启用 unattended-upgrades，并对安全更新进行自动化**([GitHub][12])
- [ ] **SHOULD：启用 apticron / apt-listchanges，把“待更新/变更摘要”发邮件**([GitHub][12])
  - 最佳实践：
    - 把“自动重启”策略写清楚（业务能否接受自动重启、是否要维护窗口）([GitHub][12])
    - 邮件能送达是前提（见后面的 exim4/Gmail 部分）([GitHub][12])

### 3.4 熵池（Entropy）与随机数（WIP 但思路可用）

- [ ] **OPTIONAL：评估是否需要额外熵源工具（例如 rng-tools）**([GitHub][12])
  - 最佳实践：现代内核与云环境下通常够用；除非你明确遇到“熵不足导致密钥生成/握手卡住”或合规要求，否则谨慎引入额外复杂度

### 3.5 “Panic/Duress Password”争议项（强烈建议你改成“安全版”）

- [ ] **OPTIONAL：是否需要“胁迫登录（duress）”机制**([GitHub][12])
  - 重要说明：repo 引用的思路包含“触发脚本删除数据/破坏系统”的叙述([GitHub][12])。**我不建议把“自动毁数据”作为默认基线**（误触发/不可逆/合规与取证风险极高）。
  - 更安全的最佳实践（推荐基线写法）：
    - 触发后只做：立刻告警（短信/邮件/IM）、锁定账号/提高审计级别、临时收紧防火墙、切换到隔离网络；
    - 数据销毁必须走“人工确认 + 多重校验”的流程，而不是一次登录就自动执行。

---

## 4) 网络侧基线（repo：UFW / PSAD / Fail2ban / CrowdSec）

### 4.1 防火墙（UFW）

- [ ] **MUST：默认拒绝入站，只放行业务需要端口**（最小暴露面）([GitHub][12])
- [ ] **SHOULD：评估是否需要“默认拒绝出站”**（更严格但更容易踩坑）([GitHub][12])
  - 最佳实践：
    - 新装服务后，先更新“端口→服务→允许对象”清单，再开规则
    - 若启用出站默认拒绝，务必提前列出：DNS、NTP、软件源、告警邮件、外部 API 等白名单，否则会出现“服务神秘不可用”([GitHub][12])

### 4.2 网络扫描/探测检测（PSAD）

- [ ] **SHOULD：启用 PSAD 监控 iptables 日志以检测扫描、指纹识别、可疑流量**([GitHub][12])
  - 最佳实践：PSAD 偏“网络层异常”，与 Fail2ban（应用日志）可互补同时使用([GitHub][12])

### 4.3 应用层防爆破（Fail2ban）

- [ ] **MUST（公网 SSH 强烈建议）：Fail2ban 监控 SSH 等服务日志并自动封禁**([GitHub][12])
  - 最佳实践：
    - 每加一个对外服务（SSH/Nginx/应用登录等），补齐对应 jail
    - 封禁策略要可回滚（白名单、解封流程）

### 4.4 CrowdSec（“带社区情报”的 Fail2ban 思路）

- [ ] **SHOULD：评估 CrowdSec（本地检测 + 社区威胁情报 blocklist）**([GitHub][12])
  - 最佳实践：适合公网暴露面较多的机器；但要明确：引入情报意味着“误封/策略变化”的可能性也更高，需监控与审计

---

## 5) 审计与持续检查（repo：AIDE / 恶意软件 / rootkit / 日志汇总 / 端口盘点 / Lynis / OSSEC）

### 5.1 文件完整性（AIDE，WIP）

- [ ] **SHOULD：用 AIDE 或同类做关键目录完整性监控（FIM）**([GitHub][12])
  - 最佳实践：把“基线数据库”当作敏感资产保护；变更要走流程（否则全是噪声）

### 5.2 恶意软件扫描（ClamAV）

- [ ] **OPTIONAL：按业务需要启用 ClamAV 扫描**（例如：有用户上传文件、邮件网关等）([GitHub][12])

### 5.3 Rootkit 检测（rkhunter / chkrootkit）

- [ ] **OPTIONAL：rkhunter / chkrootkit**（更偏“补充信号”，不要当作唯一依据）([GitHub][12])
  - 最佳实践：把告警结果纳入 SIEM/告警渠道，重点关注“基线变化”而不是一次扫描的绝对值

### 5.4 日志每日摘要（Logwatch）

- [ ] **MUST（建议）：配置 logwatch 每日邮件汇总系统日志**([GitHub][12])
  - 最佳实践：
    - 把收件人设为团队/告警渠道，而不是个人
    - 配合后面的 MTA（exim4/Gmail）确保邮件可达([GitHub][12])

### 5.5 端口盘点（ss）

- [ ] **MUST：定期核对“对外监听端口”是否符合预期**([GitHub][12])
  - 最佳实践：把“非 localhost 监听”的端口全部对齐到资产清单；发现未知服务立刻定位来源（包、容器、systemd unit、手工启动）

### 5.6 Lynis（强烈推荐纳入你的“季度基线审计”）

- [ ] **SHOULD：定期运行 Lynis 做系统级安全审计并跟踪整改项**([GitHub][12])
  - 最佳实践：每次审计输出存档，形成“趋势”（分数变化、遗留项、复发项）

### 5.7 OSSEC（HIDS）

- [ ] **OPTIONAL：部署 OSSEC 之类 HIDS 做主机入侵检测**([GitHub][12])
  - 最佳实践：如果你已经有 Wazuh/Elastic/Splunk/云厂商 HIDS，可把它作为同类能力替代

---

## 6) 危险区（Danger Zone，务必评估副作用）（repo：GRUB、root、umask、孤儿包、sysctl）

### 6.1 GRUB 加密码（物理攻击面防护）

- [ ] **OPTIONAL：为 GRUB 设置密码，防止物理访问者通过引导参数/救援模式绕过系统**([GitHub][12])
  - 最佳实践：
    - 只在“确有物理接触风险”的环境启用（机房可控通常优先做 BIOS/UEFI 口令与安全启动）([GitHub][12])
    - 把恢复流程与口令保管纳入运维制度（忘了会很痛）([GitHub][12])

### 6.2 锁定 root 直接登录（高风险操作）

- [ ] **SHOULD：在 sudo 体系正确的前提下，禁用/锁定 root 直接登录**([GitHub][12])
  - 关键风险：repo 明确警告某些系统在引导失败会用 `sulogin` 掉到 root 控制台，锁 root 可能导致无法进入救援 shell([GitHub][12])
  - 最佳实践：先验证你的救援路径（控制台/云厂商救援/带外管理/快照恢复）再决定

### 6.3 sysctl（repo 当前只给“参考链接 + 免责声明”）

- [ ] **SHOULD：建立你自己的 sysctl 基线（来自 CIS/ANSSI/发行版指南），并在灰度环境验证**([GitHub][11])
  - 重要说明：该 repo 的 sysctl 文档目前明确“多数设置作者不理解，仅供参考”([GitHub][11])
  - 最佳实践：
    - 以 CIS/ANSSI/发行版官方 hardening 为源头；
    - 每条 sysctl 变更都记录“目的/影响/回滚方式”；
    - 网络类 sysctl（rp_filter、redirect、accept_source_route 等）对业务影响大，务必在测试环境验证

### 6.4 孤儿包清理（减少攻击面）

- [ ] **SHOULD：定期清理不需要的软件/库（孤儿包）**([GitHub][12])
  - 最佳实践：删除之前先确认依赖链；保留变更记录；必要时做快照/备份

---

## 7) 告警邮件与本机 MTA（repo：exim4 + Gmail smarthost）

> 目的：让 unattended-upgrades、logwatch、PSAD 等能把告警可靠地发出来。([GitHub][12])

- [ ] **MUST：服务器具备稳定的“向外发信”能力（至少能发到运维邮箱/告警系统）**([GitHub][12])
- [ ] **SHOULD：使用 smarthost（例如 Gmail SMTP 465）并启用 TLS**([GitHub][12])
- [ ] **MUST：为本地账号配置邮件别名（aliases），确保 root/系统告警有人接收**([GitHub][12])
- [ ] **SHOULD：若你启用了 UFW 出站限制，为 SMTP TLS 放行出站规则**([GitHub][12])

---

## 8) 日志工程化（repo：iptables 单独落日志）

- [ ] **SHOULD：iptables 日志单独输出到独立文件，便于检索与取证**([GitHub][12])
  - 最佳实践：统一日志前缀；rsyslog 单独 action；并纳入日志轮转与集中采集（如有）

---

## 9) Web Server（Nginx）安全响应头（repo：`nginx.md`）

- [ ] **SHOULD：隐藏 Nginx 版本信息（`server_tokens off`）**([GitHub][10])
- [ ] **SHOULD：配置基础安全响应头**（至少覆盖常见点击劫持/嗅探/权限策略/引用策略）([GitHub][10])
  - repo 给出的头包含：
    - `Content-Security-Policy`（示例：`default-src 'self'`）([GitHub][10])
    - `X-Frame-Options SAMEORIGIN`([GitHub][10])
    - `X-Content-Type-Options nosniff`([GitHub][10])
    - `Referrer-Policy strict-origin`([GitHub][10])
    - `Permissions-Policy ...`([GitHub][10])
    - `X-XSS-Protection "1; mode=block"`（注意：现代浏览器对该头支持逐步弱化，建议你把重心放在 CSP 上）([GitHub][10])

  - 最佳实践：CSP 需要按你的站点资源实际情况定制（脚本/第三方资源/CDN/内联脚本等），不要直接照抄“一刀切”

---

## 10) 把“基线检查”做成可持续（建议你纳入长期路线）

- [ ] **MUST：能自动化审计（至少季度一次）**：OpenSCAP/SSG、USG、或 CIS 对齐工具链([open-scap.org][13])
- [ ] **SHOULD：能自动化落配置**：Ansible（例如 dev-sec hardening）+ 代码化变更记录([GitHub][7])
- [ ] **MUST：每次审计有“整改闭环”**（把 Lynis/扫描输出变成工单列表）([GitHub][12])

---

## 附：你可以直接用的“最小对外暴露面”核对表（强烈建议每台机都过一遍）

- [ ] 只有必要端口对外开放（并在资产清单中有记录）([GitHub][12])
- [ ] SSH：仅密钥登录；root 禁止；AllowGroups 限制；禁用转发；弱 DH moduli 已清理([GitHub][12])
- [ ] 有暴力破解防护（Fail2ban 或 CrowdSec 至少其一）([GitHub][12])
- [ ] 自动安全更新已启用，并且告警邮件能收到([GitHub][12])
- [ ] 每日日志摘要能收到（logwatch）([GitHub][12])
- [ ] 每季度做一次系统级审计（Lynis/OpenSCAP/USG/CIS 任选其一并留档）([GitHub][12])

---

如果你愿意，我可以在不新增工具调用的前提下，把上面的 checklist 再“拆得更细”（例如把 SSH、UFW、审计工具分别拆成 30~80 个可勾选小项，并给每项加“证据字段模板”），让它更像你自己的长期运行手册。

[1]: https://csrc.nist.gov/pubs/sp/800/123/final?utm_source=chatgpt.com "SP 800-123, Guide to General Server Security | CSRC"
[2]: https://cyber.gouv.fr/sites/default/files/document/linux_configuration-en-v2.pdf?utm_source=chatgpt.com "ANSSI GUIDELINES"
[3]: https://access.redhat.com/compliance/cis-benchmarks?utm_source=chatgpt.com "CIS Benchmarks - Red Hat Customer Portal"
[4]: https://infosec.mozilla.org/guidelines/openssh?utm_source=chatgpt.com "OpenSSH - Mozilla"
[5]: https://www.open-scap.org/?utm_source=chatgpt.com "Home | OpenSCAP portal"
[6]: https://documentation.ubuntu.com/security/compliance/usg/?utm_source=chatgpt.com "Ubuntu Security Guide (USG) - Ubuntu security documentation"
[7]: https://github.com/dev-sec/ansible-collection-hardening?utm_source=chatgpt.com "GitHub - dev-sec/ansible-collection-hardening: This Ansible collection ..."
[8]: https://github.com/trimstray/the-practical-linux-hardening-guide?utm_source=chatgpt.com "The Practical Linux Hardening Guide - GitHub"
[9]: https://www.nsa.gov/Press-Room/Cybersecurity-Advisories-Guidance/smdsearch11747/linux/?utm_source=chatgpt.com "NSA Cybersecurity Advisories & Guidance"
[10]: https://raw.githubusercontent.com/imthenachoman/How-To-Secure-A-Linux-Server/master/nginx.md "raw.githubusercontent.com"
[11]: https://raw.githubusercontent.com/imthenachoman/How-To-Secure-A-Linux-Server/master/linux-kernel-sysctl-hardening.md "raw.githubusercontent.com"
[12]: https://raw.githubusercontent.com/imthenachoman/How-To-Secure-A-Linux-Server/master/README.md "raw.githubusercontent.com"
[13]: https://www.open-scap.org/security-policies/scap-security-guide/?utm_source=chatgpt.com "SCAP Security Guide | OpenSCAP portal"

## SELinux

https://www.bilibili.com/video/BV18tawz9Emi/?spm_id_from=333.337.search-card.all.click&vd_source=f93a90ecd1f4fbda93651d654ff4c882

## AppArmor

```yaml
- url: https://github.com/containers/bubblewrap
# Bubblewrap = bwrap ➜ “把进程包在泡泡里”
#是一个在 用户空间 运行的小工具（一个可执行程序）。
#核心作用：利用 Linux 的 namespace + mount + seccomp 等机制，给程序创建一个隔离沙箱环境。
#是很多 sandbox / Flatpak 之类的底层组件。
#你可以把它想象成：
#“用 Linux 的 namespace 给进程做一个轻量级容器 / chroot++”。
#一句话总结：
#Bubblewrap = 用 namespace 做出来的“微型容器/沙箱”工具。

# 它能做啥：
# 1、隔离文件系统视图。只把某些目录绑定进去，比如只让程序看到 /usr 和一个临时的 /home。。对进程来说，感觉自己在一个独立的根目录里。
# 2、隔离进程、用户、网络等 namespace（可选）。让它看不到系统上其他进程。让它在一个单独的用户 / 网络空间
# 3、配合 seccomp 过滤系统调用。限制它能用哪些 syscalls，进一步减少攻击面。
# 4、常见用途：Flatpak 使用 Bubblewrap 给桌面应用做沙箱一些发行版或应用，用它来运行不可信脚本 / 工具

- url: https://github.com/roddhjav/apparmor.d
  des: 【AppArmor】
# AppArmor = Application Armor ➜ “给程序穿盔甲”
#属于 Linux Security Modules (LSM) 之一（和 SELinux 同一层级）。
#在 内核层 拦截进程的敏感操作（文件访问、网络、能力能力等）。
#通过 profile（配置文件/策略） 来定义：某个程序 允许做什么 / 不允许做什么。
#例如：
#/usr/bin/nginx 只能读 /var/www，不能读 /home/用户/
#/usr/bin/evince 只能读 PDF，不允许随便执行脚本之类

# 基于路径（path-based）
## 对“可执行文件的路径”写策略，比如 /usr/bin/foo，上限制规则。
## 强制访问控制（MAC）

# 即使 root，也要受策略约束。策略可以：
## 允许 / 拒绝 打开某些文件
## 控制网络访问
## 限制使用某些 capability（例如 CAP_SYS_ADMIN 等）

# 两种模式
## complain（学习 / 报告模式）：只记录违规，不拦截
## enforce（强制模式）：违规就拒绝
```

```yaml
- url: https://github.com/flatpak/flatpak
  des: 【】Flatpak 是一个在 Linux 上用来 分发、安装、运行桌面应用 的框架，同时给这些应用提供 沙箱隔离。
  # why?
  ## 不同发行版包格式太多：deb、rpm、pacman…
  ## 库版本不一致：同一个软件要为每个发行版单独打包、适配。
  ## 应用权限太大：一装上就能随便读你整个 $HOME。

  # what?
  ## 你可以把 Flatpak 当成一个 包管理器，只是它管的是 “Flatpak 应用”，而不是 apt/dnf 那种系统包。

  # how?
  ## 统一打包格式：一个包，在各种主流发行版上都能装（前提是系统支持 Flatpak）。
  ## 自带运行时（runtime）：应用带上自己需要的库，不太依赖系统里的那些版本。
  ## 沙箱运行：应用默认在隔离环境里跑，要访问文件、摄像头、网络等，都通过权限控制。

  # how it works? = Flatpak 具体怎么管 app？
  #
```

能否给我解释一下　AppArmor　和　Bubblewrap 分别是啥？

```markdown
简单说：

- **AppArmor**：Linux 内核里的一个**安全模块（LSM）**。
- **Bubblewrap（bwrap）**：一个在用户态运行的**沙箱工具**。

它们都和“限制进程权限”有关，但工作层级和方式完全不一样。

---

## 一、AppArmor 是什么？

**AppArmor = Application Armor ➜ “给程序穿盔甲”**

- 属于 **Linux Security Modules (LSM)** 之一（和 SELinux 同一层级）。
- 在 **内核层** 拦截进程的敏感操作（文件访问、网络、能力能力等）。
- 通过 **profile（配置文件/策略）** 来定义：某个程序 **允许做什么 / 不允许做什么**。
  例如：
  - `/usr/bin/nginx` 只能读 `/var/www`，不能读 `/home/用户/`
  - `/usr/bin/evince` 只能读 PDF，不允许随便执行脚本之类

**特点：**

1. **基于路径（path-based）**
   对“可执行文件的路径”写策略，比如 `/usr/bin/foo`，上限制规则。

2. **强制访问控制（MAC）**
   即使 root，也要受策略约束。策略可以：
   - 允许 / 拒绝 打开某些文件
   - 控制网络访问
   - 限制使用某些 capability（例如 `CAP_SYS_ADMIN` 等）

3. **两种模式**
   - complain（学习 / 报告模式）：只记录违规，不拦截
   - enforce（强制模式）：违规就拒绝

4. **常见场景**
   - Ubuntu、openSUSE 默认就带 AppArmor，用来保护：
     - 浏览器
     - SSH、数据库、web 服务器
     - 各种后台服务

可把它理解成：**“在系统全局层面给程序定一份安全白名单”**。

---

## 二、Bubblewrap 是什么？

**Bubblewrap = bwrap ➜ “把进程包在泡泡里”**

- 是一个在 **用户空间** 运行的小工具（一个可执行程序）。
- 核心作用：利用 Linux 的 **namespace + mount + seccomp 等机制**，给程序创建一个**隔离沙箱环境**。
- 是很多 sandbox / Flatpak 之类的底层组件。

你可以把它想象成：

> “用 Linux 的 namespace 给进程做一个轻量级容器 / chroot++”。

**它能做啥：**

1. **隔离文件系统视图**
   - 只把某些目录绑定进去，比如只让程序看到 `/usr` 和一个临时的 `/home`。
   - 对进程来说，感觉自己在一个独立的根目录里。

2. **隔离进程、用户、网络等 namespace**（可选）
   - 让它看不到系统上其他进程
   - 让它在一个单独的用户 / 网络空间

3. **配合 seccomp 过滤系统调用**
   - 限制它能用哪些 syscalls，进一步减少攻击面。

4. **常见用途：**
   - Flatpak 使用 Bubblewrap 给桌面应用做沙箱
   - 一些发行版或应用，用它来运行不可信脚本 / 工具

一句话总结：

> **Bubblewrap = 用 namespace 做出来的“微型容器/沙箱”工具。**

---

## 三、两者的对比与关系

可以用一个类比：

- **AppArmor** 像「小区里的**保安制度 + 门禁系统**」：
  - 整个系统级别的规则
  - 谁可以进哪栋楼、哪间屋、几点能进等

- **Bubblewrap** 像「在某个屋里又搭了一个 **临时隔断小屋**」：
  - 把人关在一个小空间里
  - 即使小区规则允许你很多事情，在这个小空间里你能看到 / 接触到的东西有限

**区别点：**

1. **层级不同**
   - AppArmor：内核 LSM，属于 MAC 框架的一部分。
   - Bubblewrap：普通用户态程序，调用内核 syscalls 创建 namespace / mount 等。

2. **配置方式不同**
   - AppArmor：写 profile（文本策略），系统统一加载。
   - Bubblewrap：每次启动进程时，用命令行参数描述沙箱（挂载点、namespace 设置等）。

3. **生效范围**
   - AppArmor：对某个程序的所有实例都能生效（只要开启 profile）。
   - Bubblewrap：只对你用 bwrap 启动的那个进程 / 子进程生效。

4. **可以叠加使用**
   - 一个通过 Bubblewrap 启动的进程，**同时** 也可以受 AppArmor 限制。
   - 也就是说：
     - 外面有一层 AppArmor 的“系统级规则”
     - 里面有一层 Bubblewrap 的“沙箱隔离”

---

## 四、什么时候用哪个？

- **如果你是系统管理员**：
  - 想给系统服务 / 某些程序统一加安全策略 → 考虑 **AppArmor（或 SELinux）**。
  - 多用户机器上，保护关键服务、守护进程 → AppArmor 很合适。

- **如果你是应用开发者 / 想给自己的程序做沙箱**：
  - 想在用户态就能控制“我启动的这个进程看到什么” → **Bubblewrap** 很好用。
  - 写自己的包管理器 / 容器式运行环境 / Flatpak 风格的桌面应用 → 常用 bwrap。

---

如果你愿意，我可以：

- 给你写一个 **简单 AppArmor profile 示例**，比如限制一个程序只能访问 `/tmp`；
- 再配一个 **Bubblewrap 命令示例**，比如把某个脚本扔到只读根目录 + tmpfs 的沙箱里跑。
```

# LUKS2

```markdown
https://leo3418.github.io/collections/gentoo-config-luks2-grub-systemd/packages.html

https://forums.puri.sm/t/libreboot-with-full-disk-encryption-including-boot-luks2-argon2id/22606

与linux相关的问题

为啥有些人做了全盘加密？相较于不加密，有啥优缺点？

是否目前的主流方案就是　LUKS2?

除此之外还有哪些方案？
```

```markdown
先说结论：

- 很多人做“全盘加密”（尤其是笔电、移动硬盘、服务器）主要是为了**防物理丢失/被偷时的数据安全**，以及防止线下篡改系统。
- 相比不加密：
  - **优点**：数据泄露难度大大提高、可以放心丢电脑/硬盘、做运维交接更安心。
  - **缺点**：有一点性能损耗、启动流程更复杂（要输入密码/用钥匙）、恢复出错更麻烦（头丢了就真丢了）。

- 在 Linux 世界里，目前主流确实是 **dm-crypt + LUKS（现在新系统多是 LUKS2 头）**([Red Hat Docs][1])
- 但 LUKS2 不是唯一方案，还有：**文件级加密（fscrypt、eCryptfs）、容器型加密（VeraCrypt）、厂商自带方案（BitLocker、macOS FileVault）** 等等。([Wikipedia][2])

下面分点展开说。

---

## 一、为啥要“全盘加密”（Full Disk Encryption, FDE）？

这里指的是：整个根分区甚至包括 `/home`、swap 等所有 block 设备都在加密层之下，只有（有的方案甚至连 `/boot` 也加密）在输入密码后才解密挂载。

### 1. 典型威胁模型

1. **笔记本被偷 / 遗失**：
   - 如果没加密，只要拿个 U 盘启动，或者拆盘到另一台机上，里面所有文件都能直接读。
   - 如果全盘加密，即使对方拿到物理硬盘，没有密钥就只是一堆随机噪音。

2. **边检 / 海关 / 公司 IT 部门要检查机器**：
   - 有的人会准备“干净系统”或“诱饵系统”，真资料在加密盘中。
   - 有的只靠强密码 & 全盘加密，让对方没法在你人离场后“悄悄拷盘”。

3. **线下篡改系统（evil maid attack）**：
   - 如果 `/boot` 是明文的，攻击者可以改 kernel/initramfs，在你下次引导时窃取密码。
   - 有些人连 `/boot` 都放在 LUKS2 里面（你给的第二个链接就是讨论 Libreboot + 全盘 LUKS2）来减小这类攻击面。([Wikipedia][3])

4. **企业合规 / 审计要求**：
   很多公司规定笔记本硬盘必须加密，不加密不允许存放生产数据或客户数据([Linux Security][4])。

### 2. 优点（相对“不加密”）

**安全层面：**

- 硬盘被盗/丢失 → 数据很难恢复。
- 防止轻度“取证”：别人拿着盘跑到数据恢复公司，也只能看到加密块。
- 可以比较安心地处理报废硬盘：只要销毁密钥，盘上数据就“数学意义上”不可恢复。

**管理层面：**

- 统一方案：Linux 各大发行版安装时都原生支持 LUKS2，全盘加密配置很标准([Linux Security][4])。
- 支持多钥槽：可以给不同管理员设置不同密码、Keyfile，随时吊销某个密码而不重加密整盘([Wikipedia][3])。

### 3. 缺点 / 代价

1. **性能损耗**
   - CPU 需要对每个读写块做加解密。
   - 现代 CPU 有 AES-NI 等指令集，**正常桌面 / 笔电负载下性能损失通常只有个位数百分比**，数据库或高 IOPS 场景可能更明显([Phoronix][5])。

2. **启动流程更麻烦**
   - 通常需要在 initramfs 阶段输入一次解密密码，才挂载 root 分区。
   - 如果 `/boot` 也加密，还要考虑 bootloader（GRUB、systemd-boot、coreboot/Libreboot payload）是否支持解锁 LUKS2，并在那一层输入密码。

3. **恢复容错性变差**
   - LUKS 头损坏就麻烦了：没 header 等于没密钥参数，数据基本救不回来（除非有 header 备份）([Wikipedia][3])。
   - 忘记密码、丢了 keyfile、TPM 状态变了，要恢复数据非常难。

4. **某些场景不适合加密**
   - 比如单纯做缓存盘、CDN 边缘节点存的是可公开内容、或者被当成“临时 scratch disk”的存储，有时候就懒得加密，节约一点性能和复杂度。

---

## 二、LUKS2 现在是不是“主流方案”？

基本可以说：在 Linux 上，面向**块设备加密（特别是全盘加密）**时，**dm-crypt + LUKS 是事实标准**，而其中新部署普遍倾向使用 **LUKS2**：

- Red Hat / RHEL8+、RHEL10 文档直接写：默认格式已是 LUKS2，LUKS1 只保留兼容用途([Red Hat Docs][6])。
- 近期的 Linux 安全和教程文章也都以 **dm-crypt + LUKS2** 作为默认推荐方案([LinuxMind][7])。
- LUKS2 相比 LUKS1 的优势大致包括：
  - header 改为二进制 + JSON，元数据有冗余，更容易检测/修复损坏。
  - 支持更多 keyslot、在线重新加密、更灵活的 KDF（比如默认 Argon2id）、元数据扩展性更好([Baeldung on Kotlin][8])。

不过：

- 旧系统、旧 bootloader、某些 embedded 设备，可能还是只支持 LUKS1。
- 某些发行版仍然在“最大兼容”模式下默认 LUKS1，但都会提供 `--type luks2` 选项，让你手动选([Ask Ubuntu][9])。

所以可以说：

> **现在 Linux 上做全盘加密，首选、也最主流的方案就是：dm-crypt + LUKS2（只要 bootloader / 环境支持，就尽量用 LUKS2）。**

---

## 三、除了 LUKS2，还有哪些常见方案？

从“怎么加密磁盘/文件”的角度，可以按层次分一下：

### 1. 块设备级（整盘 / 分区加密）

- **dm-crypt + LUKS1 / LUKS2**（Linux 原生）
  - 现在是标准答案，上面已经说了。

- **BitLocker**（Windows）
  - Windows 自带的整盘/系统盘加密，支持与 TPM（可信平台模块）结合，用 PIN 或 USB key 做二次验证([Wikipedia][2])。

- **macOS FileVault 2**
  - 苹果在 macOS 上提供的整盘加密方案。

- **其他专有企业级产品**：Check Point Full Disk Encryption、DriveLock 等，多用于企业环境([Wikipedia][2])。

这些方案基本都是“对整个块设备加密”，特点是：**应用层完全感知不到加密存在**。

### 2. 容器型 / 虚拟磁盘加密

- **VeraCrypt**（TrueCrypt 的继任者）([AlternativeTo][10])
  - 跨平台（Windows、macOS、Linux），可以创建加密文件容器，也可以加密整盘。
  - 对于需要在不同 OS 间移动盘的用户很常见。

- 早期的 **TrueCrypt**（已停止维护，不建议新项目再用）([Wikipedia][2])。

和 LUKS 的区别：LUKS 更偏 Linux 原生、统一 on-disk 格式；VeraCrypt 更适合跨平台使用和“隐匿卷”等特性。

### 3. 文件系统级加密

这类方案不是加密整个块设备，而是**某个文件系统上的文件/目录**：

- **fscrypt（EXT4 / F2FS / UBIFS 原生支持）**([Phoronix][5])
  - Linux 内核的通用框架，EXT4 从 4.1 开始有支持。
  - 优点：可以只加密某些目录（比如 `~/Secrets`）、每个用户不同密钥、性能比全盘加密更好（尤其是只用在某些目录时）。
  - 缺点：元数据（文件大小、目录结构等）通常还是可见，威胁模型不太一样。

- **eCryptfs**（以前 Ubuntu 的“加密 home 目录”用的）
  - 现在基本被 fscrypt 和 LUKS 取代，已经不推荐新部署([LFCS Certification Prep eBook][11])。

这类适合：

> “系统不用管，只有某些用户数据要加密”，比如多用户共享机器，只想加密个人目录。

### 4. 应用层 / 文件级加密

- **GnuPG (GPG)**：加密单个文件或邮件，而不是盘([JumpCloud][12])。
- 备份工具自带的加密（如 restic、borgbackup）。

这类更多是为了**数据在传输、备份过程中的安全**，而不是设备被盗时的“盘级安全”。

---

## 四、什么时候值得用“全盘加密”？什么时候可以不必？

**适合全盘加密的情况：**

- 笔记本、移动办公设备。
- 存在客户数据、生产数据库、代码仓库、SSH Key 等敏感信息。
- 监管/合规有要求（金融、医疗、政府项目等）。
- 你愿意为安全多输入一次密码、多做一次备份。

**可以考虑不用全盘加密、或只部分加密的情况：**

- 只做游戏 / 娱乐 / 不存任何重要私人数据的机器。
- 用作缓存 / CI builder / 临时计算节点的服务器，所有东西都在别处有明确备份，并且已经做了网络访问控制。
- 你更在意每一点 I/O 性能，而且机器本身物理安全有保障（机房、加固机柜等）。

实际很多人会折中：

- 系统盘全盘 LUKS2；
- 再配合 `fscrypt` 或加密 home 目录；
- SSH key、密码库再单独用 GPG / 密码管理器加密一次。

---

## 五、如果你打算自己搞一套的话，简单建议

结合你给的那两个链接（Gentoo + LUKS2 + systemd, Libreboot + 全盘 LUKS2）和目前的主流实践，可以给个大致路线图（不细到命令行）：

1. **优先选 LUKS2**，除非：
   - 要兼容特别老的 bootloader / 怪异发行版；
   - 或者某些嵌入式场景明确说只支持 LUKS1。

2. **算法：**
   - 默认 `aes-xts-plain64` + 合理长度（比如 512bit key，即 256bit\*2），已经足够安全([Wikipedia][3])。
   - KDF 用 Argon2id（LUKS2 默认），并根据你机器性能调节 `time/memory/cpus`。

3. **务必备份 LUKS header**：
   - 新建好后直接 `cryptsetup luksHeaderBackup` 保存到离线 U 盘 / 密码管理器里，这比什么都重要。

4. **认真考虑 `/boot` 是否加密**：
   - 若 bootloader 支持 LUKS2，整盘加密更安全，但遇到问题也更难排错。
   - 若刚入门，第一台机可以先“只加密 root + home，不加 `/boot`”，熟练以后再折腾全盘。

---

如果你愿意，我也可以帮你**根据你目前用的发行版（比如 Arch / Gentoo / Debian / Fedora / Ubuntu）和分区情况，设计一套具体的分区 & LUKS2 方案**，包括：

- 哪些分区建议加密/不加密
- 是否要用 LVM-on-LUKS
- 大致的安装/迁移步骤和可能踩的坑

[1]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/managing_storage_devices/encrypting-block-devices-by-using-luks?utm_source=chatgpt.com "Chapter 17. Encrypting block devices by using LUKS"
[2]: https://en.wikipedia.org/wiki/Comparison_of_disk_encryption_software?utm_source=chatgpt.com "Comparison of disk encryption software - Wikipedia"
[3]: https://en.wikipedia.org/wiki/Linux_Unified_Key_Setup?utm_source=chatgpt.com "Linux Unified Key Setup"
[4]: https://linuxsecurity.com/features/authoritative-guide-on-linux-disk-encryption?utm_source=chatgpt.com "Disk Encryption: An Authoritative Guide for Linux Users"
[5]: https://www.phoronix.com/review/ext4-crypto-418?utm_source=chatgpt.com "EXT4 fscrypt vs. eCryptfs vs. LUKS dm-crypt Benchmarks"
[6]: https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/security_hardening/encrypting-block-devices-using-luks_security-hardening?utm_source=chatgpt.com "Chapter 9. Encrypting block devices using LUKS - Red Hat"
[7]: https://linuxmind.dev/2025/09/02/full-disk-encryption-with-luks/?utm_source=chatgpt.com "Full Disk Encryption with LUKS - linuxmind.dev"
[8]: https://www.baeldung.com/linux/luks1-vs-luks2?utm_source=chatgpt.com "LUKS1 vs. LUKS2 for Partition Encryption | Baeldung on Linux"
[9]: https://askubuntu.com/questions/1032546/should-i-use-luks1-or-luks2-for-partition-encryption?utm_source=chatgpt.com "Should I use LUKS1 or LUKS2 for partition encryption?"
[10]: https://alternativeto.net/software/luks/?utm_source=chatgpt.com "LUKS Alternatives: 25+ Disk Encryption Tools & Similar Apps"
[11]: https://www.tecmint.com/file-and-disk-encryption-tools-for-linux/?utm_source=chatgpt.com "10 Best Linux File and Disk Encryption Tools (2024) - Tecmint"
[12]: https://jumpcloud.com/blog/comparing-encryption-tools-linux?utm_source=chatgpt.com "Comparing Encryption Tools: Analysis of Different Encryption Tools ..."
```

https://www.phoronix.com/news/Linus-Torvalds-Too-Many-LSM
