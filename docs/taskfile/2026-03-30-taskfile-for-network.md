---
title: taskfile for network 重构复盘
type: review
status: active
date: 2026-03-30
updated: 2026-04-01
tags: [taskfile, network]
summary: 复盘本轮 .taskfile/network 的收敛原则，以及 DNS、firewall、HTTP、perf、IP/ICMP 与 root include 的阶段性结果。
---


这篇 review 只复盘两件事：这一轮为什么这样重构 `.taskfile/network`，以及最终各个目录被收敛成了什么样子。除此之外的过程性讨论、临时分歧和中间试错，都不再展开。



## 本轮重构原则

这轮调整的出发点，不是给 `network` 再补更多命令入口，而是先把边界收干净。原先这组 Taskfile 更偏“按工具平铺”，目录里同时存在大量功能重叠、调用频率不高、或者语义层级混杂的入口。继续在这个基础上累加，只会让 `.taskfile/network` 越来越像命令索引，而不是一套稳定可复用的网络诊断入口。

因此，这轮重构实际遵循了四条原则。

第一，尽量从“工具导向”转向“场景导向”。也就是说，优先保留用户真正会反复执行的动作，而不是机械为每个 CLI 单独保留一个 Taskfile。例如 HTTP 层最终收敛到 `Taskfile.curl.yml`，保留的是 `head`、`get`、`post-json`、`download` 这些高频动作，而不是继续并列维护 `curl`、`httpie`、`wget` 三套入口。

第二，优先删除可替代工具。只要多个 CLI 在当前仓库里的高频场景明显重叠，就不再为了“工具更全”而强行并存。像 DNS 这一层只保留 `dig`；吞吐测试只保留 `iperf3`；ICMP 增强探测只保留 `nping`；路径探测则把 `tracepath` 收进 `Taskfile.traceroute.yml`，而不是继续单独占文件。

第三，只保留高频动作，把低频、强环境绑定、或者语义偏管理面的内容先移出去。比如 DNS 里不再混放 resolver service 管理、cache flush、daemon stats 这类 task；perf 里不再把 throughput test、packet generation、traffic crafting 混成一个目录；firewall 里明确分成 `nft` 的规则面和 `conntrack` 的状态面，而不再继续保留 `iptables` 的并列入口。

第四，root include 必须和真实文件布局一致。对 `.taskfile/Taskfile.yml` 来说，include path 不只是“能跑就行”的技术细节，它本身也是整个 network taxonomy 的对外接口。只有把入口名、文件名和目录布局统一起来，后续这套 Taskfile 才能持续演进，而不是不断出现旧路径残留、同义入口并存、或者 include 已经指向失效文件的问题。

这四条原则合起来，决定了这轮重构的整体方向：不是继续扩充 `.taskfile/network` 的工具覆盖面，而是先把它收敛成一套更稳定的网络诊断 task 集合。换句话说，本轮更关心“入口是否清晰、能力是否重复、结构是否还能继续长”，而不是“是否把所有可用命令都包了一层”。

## 本轮目录级产出

这轮调整之后，`.taskfile/network` 的主要结果可以直接按目录来看。

### DNS

DNS 这一层统一收敛到了 `.taskfile/network/Taskfile.DNS.yml`。这轮删掉了大量 resolver / cache / service 管理相关 task，最终只保留 `dig` 的高频查询动作，包括 `answer`、`short`、`resolver`、`trace`、`reverse`。它现在表达的是“DNS 查询入口”，而不是“本机 DNS 环境管理入口”。

### firewall

firewall 这一层统一收敛到了 `.taskfile/network/Taskfile.firewall.yml`。规则面保留 `nft`，状态面保留 `conntrack`，对应核心 task 是 `rules`、`trace`、`state`、`find`、`stats`。`iptables` 不再继续作为并列入口保留，目录语义也因此变得更直接。

### HTTP

HTTP 这一层统一收敛到了 `.taskfile/network/Taskfile.curl.yml`。这轮删除了原先独立的 `httpie` 和 `wget` task，只保留基于 `curl` 的 `head`、`get`、`post-json`、`download`，并保留 `default -> head` 的兼容入口。最终留下的是“高频 HTTP 动作”，而不是“多个 HTTP CLI 的并列包装”。

### perf

性能测试这一层统一收敛到了 `.taskfile/network/Taskfile.iperf.yml`。这轮明确删掉了 `netperf`、`pktgen`、`trafgen`，只保留 `iperf3` 对应的 `server`、`tcp`、`udp`、`parallel`、`bidir`。这意味着 `network/perf` 的边界已经被明确收窄为“端到端吞吐测试”，不再继续混放 packet generation 或 traffic crafting 工具。

### IP / ICMP

IP 这一层这轮主要做的是“先砍掉可替代工具，再把高频动作收进稳定入口”。

连通性相关动作统一收进了 `.taskfile/network/Taskfile.ping.yml`。这里保留的是 `ping` 为主入口，同时把 `fping` 的批量探测能力收成 `batch`、`sweep`，把 `mtr` 的路径质量观察收成 `path`、`path:v6`。这层现在表达的是“connectivity workflow”，不再是三个并列工具文件。

增强探测相关动作统一收进了 `.taskfile/network/Taskfile.nping.yml`。这里删除了 `hping3`，保留 `nping` 的 `icmp`、`pmtu`，并把 `nstat` 也一起收进来作为 `stats`。这一层的定位因此变成了“增强 probe + 诊断证据”，而不是可定制 packet 工具集合。

路径探测相关动作统一收进了 `.taskfile/network/Taskfile.traceroute.yml`。这里保留 `traceroute` 的默认、`icmp`、`tcp`、`darwin` 变体，同时把 `tracepath` 收成 `tracepath`、`tracepath:v6`。这样路径探测只保留一个主入口，但仍然保留通用 tracing 和轻量 PMTU 视角两种能力。

系统网络状态相关动作统一收进了 `.taskfile/network/Taskfile.iproute2.yml`。这里保留 `ip` 的 `link`、`addr`、`route`、`route6`、`rule`、`neigh`、`monitor`、`route:get`，并把 `tc` 收成 `qdisc`、`class`、`filter`。也就是说，这一层现在表达的是“IP 路由与接口状态检查”。

### playbook

场景化诊断动作保留在 `.taskfile/network/Taskfile.z.yml`。这一层没有继续按单一工具扩张，而是明确保留像 `pmtu:quick` 这样的 playbook，把 `tracepath + DF ping` 这类常见排障路径固化成可复用 task。它的意义不是增加工具种类，而是把“多步诊断流程”单独沉淀下来。

### root include

这一轮也同步整理了 `.taskfile/Taskfile.yml` 里的 network include，使其和当前已经收敛后的文件布局保持一致。当前 network 相关入口已经直接指向：

- `network/Taskfile.DNS.yml`
- `network/Taskfile.firewall.yml`
- `network/Taskfile.curl.yml`
- `network/Taskfile.iperf.yml`
- `network/Taskfile.ping.yml`
- `network/Taskfile.nping.yml`
- `network/Taskfile.traceroute.yml`
- `network/Taskfile.iproute2.yml`
- `network/Taskfile.z.yml`

这一步的意义，不只是修 path，而是把 root 入口的语义也一起收口。现在从 `.taskfile/Taskfile.yml` 往下看，network 这组 include 已经基本符合“一个领域一个入口文件”的结构。

这一轮之后，`.taskfile/network` 的整体形态已经比较清楚了：工具并列明显减少，目录边界比之前稳定得多，高频动作被集中到了少数几个主入口里，而场景化 playbook 也开始有了明确位置。对后续继续演进来说，这比单纯增加更多 task 更重要。
