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
