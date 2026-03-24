---
title: sing-box 在 macOS 唤醒后长时间断网问题的诊断和fix
type: review
status: active
slug: /2026/singbox-darwin-wake-recovery
date: 2026-03-20
updated: 2026-03-20
unlisted: true
tags:
  - sing-box
  - mac
  - review
---

:::tip

相关具体代码查看

[fix(singbox): 处理sing-box 在 macOS 唤醒后长时间断网问题 · xbpk3t/dotfiles@4cd4fad](https://github.com/xbpk3t/dotfiles/commit/4cd4fadae4ef22a71cf569b4e0b2b136c207815f)

:::

# sing-box 在 macOS 唤醒后为什么会坏，以及这次方案为什么有效

这次问题的核心，不是 “Wi-Fi DNS 配错了”，而是 **macOS sleep/wake 之后，sing-box 的运行态和系统网络态失同步了**。

证据很直接：排障记录里，Wi-Fi DNS 一直还是 `223.5.5.5`，`launchctl print system/local.singbox.tun` 也显示进程仍然是 `running`；但一旦执行 `launchctl kickstart -k system/local.singbox.tun`，连通性马上恢复，`chatgpt.com` 和 `www.youtube.com` 的 TLS 握手恢复正常，而且连接目标重新回到 FakeIP（`fc00::/18` / `198.18.0.0/15`）这条预期链路上。说明坏掉的是运行时状态，不是静态配置本身。

## 为什么这个方案有效

这次生效的原因，本质上是把问题拆成了三个层面分别处理。

第一层是把 **Darwin 上会卡死启动的缓存路径** 关掉。原始日志里已经明确出现过下面这类报错：

```text
FATAL[0009] start service: initialize cache-file: timeout
```

对应修改在

```nix [lib/singbox/config.nix]
experimental = {
  cache_file =
    if isDarwin
    then {
      enabled = false;
    }
    else {
      enabled = true;
      store_fakeip = true;
      store_rdrc = true;
      path = "/var/lib/sing-box/cache.db";
    };
};
```

这一步有效，是因为它直接移除了 Darwin 上最明显的失败点。之前 sing-box 在唤醒后重拉运行态时，可能卡在 `cache_file` 初始化；一旦这里超时，daemon 虽然可能还有残余状态，但实际代理链路已经不可信。禁用它之后，Darwin 至少不会再因为这个已知点把服务拉坏。

第二层是把 **DNS 语义重新理顺**，避免 “local / remote 看起来分开了，实际上还指向同一个 upstream” 这种混乱配置。对应修改在

```nix [lib/singbox/dns.nix]
final = "remote";

rules = [
  {
    clash_mode = "direct";
    query_type = [ "A" "AAAA" ];
    server = "local";
    disable_cache = true;
  }
  {
    clash_mode = "global";
    query_type = [ "A" "AAAA" ];
    server = "remote";
    disable_cache = true;
  }
  {
    rule_set = "geosite-geolocation-cn";
    query_type = [ "A" "AAAA" ];
    server = "local";
    disable_cache = true;
  }
  {
    query_type = [ "A" "AAAA" ];
    rewrite_ttl = 1;
    server = "fakeip";
  }
];
```

以及：

```nix [lib/singbox/dns.nix]
{
  type = "https";
  tag = "local";
  server = "223.5.5.5";
  path = "/dns-query";
}
{
  type = "https";
  tag = "remote";
  server = "1.1.1.1";
  path = "/dns-query";
  detour = "select";
}
```

这一步有效，是因为它解决了两个问题。

- `final = "remote"` 让未命中规则的域名不再回落到本地 resolver。
- `remote = 1.1.1.1 + detour=select` 让 foreign 解析和国内 `223.5.5.5` 真正解耦，不会再出现“名字叫 remote，实际还是 local 上游”的情况。

再加上把 `clash_mode=direct/global` 和 `CN real IP` 规则放到 FakeIP 前面，最终效果就是：该 real IP 的域名能稳定拿到 real IP，该 FakeIP 的域名再进入 FakeIP 池，模式切换后也不容易留下 stale 结果。

第三层才是这次最关键的部分：**把 wake 之后的恢复动作做成最小修复闭环**。对应修改在：

```nix [modules/darwin/singbox-client.nix]
wait_for_network_ready

if ! launchctl kickstart -k system/local.singbox.tun; then
  warn "kickstart failed; fallback to bootout/bootstrap"
  launchctl bootout system "${launchdPlist}" || true
  launchctl bootstrap system "${launchdPlist}" || true
fi

wait_for_launchd_ready || true

dscacheutil -flushcache || true
killall -HUP mDNSResponder || true
```

以及：

```nix [modules/darwin/singbox-client.nix]
launchd.daemons = {
  sing-box-tun = {
    serviceConfig = {
      Label = "local.singbox.tun";
      ProgramArguments = [
        "${pkgs.sing-box}/bin/sing-box"
        "run"
        "-c"
        "${clientConfigPath}"
      ];
      RunAtLoad = true;
      KeepAlive = {
        SuccessfulExit = false;
        NetworkState = true;
      };
    };
  };
} // optionalAttrs cfg.autoRecoverOnWake {
  sing-box-wake-recover = {
    serviceConfig = {
      Label = "local.singbox.wake-recover";
      ProgramArguments = [
        "${lib.getExe pkgs.sleepwatcher}"
        "-V"
        "-w"
        "${singboxWakeHook}"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
};
```

这一步有效，是因为它正好命中了根因。sleep/wake 之后，macOS 会重建 Wi‑Fi、scoped resolver、utun、路由等上下文；但 `launchd` 只保证“进程还活着”，并不保证 “这个进程持有的网络上下文还是有效的”。所以正确做法不是继续堆更多静态配置，而是在 wake 后：

1. 先等网络接口恢复。
2. 再 `kickstart -k` 强制重建 sing-box 运行态。
3. 如果 job 卡住，再 `bootout/bootstrap` 硬重建。
4. 最后刷新 macOS DNS cache，清掉旧 resolver 残留。

这个顺序和排障记录里的人工恢复动作一致，所以它不是“猜测型修复”，而是把已经验证有效的人工操作固化成了自动化恢复流程。

## 这次哪些改动是核心，哪些只是辅助

真正的核心改动有三项：

- Darwin 上禁用 `cache_file`
- DNS 规则重排，并把 `remote` 从 `223.5.5.5` 改成 `1.1.1.1 + detour=select`
- 新增 wake 自动恢复 hook，只做最小恢复动作

`lib/singbox/singbox-netdiag.sh` 也很重要，但它更偏 **诊断和验证工具**，不是根因修复本身。它的价值在于把现场证据采全，并把人工恢复动作标准化，例如：

```bash [lib/singbox/singbox-netdiag.sh]
run_priv_allow_fail "launchctl kickstart -k system/local.singbox.tun" launchctl kickstart -k system/local.singbox.tun
if ! wait_for_launchd_healthy || ! wait_for_singbox_runtime_ready; then
  run_priv_allow_fail "launchctl bootout system ${LAUNCHD_PLIST}" launchctl bootout system "${LAUNCHD_PLIST}"
  run_priv_allow_fail "launchctl bootstrap system ${LAUNCHD_PLIST}" launchctl bootstrap system "${LAUNCHD_PLIST}"
fi

run_priv_allow_fail "dscacheutil -flushcache" dscacheutil -flushcache
run_priv_allow_fail "killall -HUP mDNSResponder" killall -HUP mDNSResponder
```

它证明了“重建运行态”这条路径确实能把网络拉回来，也给后续自动化提供了依据。

## 一个需要明确排除的点

当前 staged changes 里还有 `modules/darwin/users.nix` 的 `restartNixDaemonIfConfigChanged`。这个改动解决的是 Determinate Nix 配置更新后 `nix-daemon` 不重载的问题，和 sing-box 的 wake 故障不是同一条因果链，不应该混进这次结论里。

## 最终结论

:::tip

这次方案之所以有效，不是因为“换了个 DNS 就好了”，而是因为它同时做对了三件事：先去掉 Darwin 上会把 sing-box 启动卡死的 `cache_file`，再把 DNS 规则和 upstream 语义理顺，最后把 wake 后必须执行的“重建运行态”固化成自动恢复流程。这样处理之后，静态配置、解析链路和运行时恢复三层终于对齐了，所以问题才真正稳定消失。

:::
