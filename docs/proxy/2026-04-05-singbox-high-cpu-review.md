---
title: sing-box 高 CPU review
date: 2026-04-05
type: review
---


## 现象

- macOS 上 `sing-box` 偶发出现高 CPU，占用可到 `300%+`
- 出现后执行下面三条命令通常可以恢复

```bash
sudo launchctl bootout system /Library/LaunchDaemons/local.singbox.tun.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/local.singbox.tun.plist
sudo launchctl kickstart -k "system/local.singbox.tun"
```

## 目前怎么处理

- 先保留本次 Nix fix，降低 Darwin 上 `sing-box` 的日志放大效应
- 已把 Darwin 运行日志级别从 `info` 降到 `warn`
- 已去掉 FakeIP 规则里的 `rewrite_ttl = 1`
- 目的不是宣称问题已经根治，而是先拿掉 CPU / I/O 放大器，避免现场被大日志污染

## 还有什么问题未处理

- 问题仍然是偶发，不是稳定复现
- 现有判断是“日志放大器”已确认存在，但未证明它是唯一根因
- 更像是某个运行态异常在先，日志与高频 DNS/连接事件把 CPU 放大了
- 重点怀疑项：
  - `urltest` 在异常网络状态下持续测速
  - `remote DNS = 223.5.5.5 + detour=select` 在某些时刻进入异常重试
  - sleep/wake 后 TUN 和系统网络状态短暂失配
  - 某个客户端应用自己在疯狂重连，`sing-box` 只是被动承压

## 怎么排查

- 下次复现时，不要先重启 `sing-box`
- 先直接运行现场抓取脚本：

```bash
bash lib/singbox/singbox-netdiag.sh --high-cpu-snapshot
```

- 脚本会额外抓这些高 CPU 现场信息：
  - `ps -p <pid> -o pid,ppid,%cpu,%mem,etime,state,command`
  - `lsof -p <pid>`
  - `netstat -anv | rg '223.5.5.5|8443|9090|53'`
  - `launchctl print system/local.singbox.tun`
  - `tail -n 180 /tmp/singbox.log`
  - `curl -s 127.0.0.1:9090/connections`（如果 clash api 可用）

- 输出日志默认会落到 `~/Library/Logs/singbox-netdiag-<timestamp>.log`
- 抓完现场之后，再决定是否执行 bootout / bootstrap / kickstart 恢复

## 修改wapd等DNS配置（来避免部分噪声） [2026-04-07]

这次对 `sing-box` 配置又做了两处收敛修改：


- 在 `dns.rules` 里把 `AdGuardSDNSFilter` / `chrome-doh` 和 `wpad` 改为 `action = "reject"`，并把这些规则提前到 `clash_mode` 规则之前，避免先被 `direct/global` 模式短路
- 把 `urltest.interval` 从 `5m` 调整为 `30m`，先降低异常网络状态下的周期性探测放大


这次修正解决的是一个确定存在的配置问题：

- `wpad` / `chrome-doh` 规则之前实际没有命中
- `server = "block"` 这种旧写法会带来额外错误日志


---


仍需继续观察的点：


- 后续是否还会出现 `300%+` 的高 CPU 现场
- `/tmp/singbox.log` 里是否还会持续出现 `bad rdata / buffer size too small`
- 即使 `wpad` 噪音下降后，是否还存在某个客户端或某条 DNS/TUN 路径在异常态下持续重试

当前结论仍然保持保守：

- 这轮修改更像是移除了已确认的配置层放大器
- 还不能证明它就是 sing-box 高 CPU 的唯一根因

### 开盖后的瞬时 `no route to internet` 日志

- 2026-04-07 又观察到一批 `dial tcp ...: no route to internet` 日志，同时影响了：
  - 直连 DoH（如 `223.5.5.5:443`）
  - 代理节点出站（如 `142.171.154.61:8443`）
- 结合当时是在刚开盖后的恢复窗口触发、随后网络自行恢复，这批日志更像 Darwin 网络 / TUN / 默认路由尚未完全恢复时的瞬时错误，而不是新的稳定配置缺陷。
- 当前先不继续为这类日志单独改 `sing-box` 配置，后续重点观察两点：
  - 这类错误是否只出现在 wake recovery 的短窗口内
  - 它是否会再次演变成需要手动 `kickstart` 或导致高 CPU 的持续故障
