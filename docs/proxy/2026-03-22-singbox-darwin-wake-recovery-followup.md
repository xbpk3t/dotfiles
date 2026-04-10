---
title: sing-box 在 mac 唤醒后断网问题的后续复盘
type: review
status: active
date: 2026-03-22
updated: 2026-03-22
isOriginal: false
tags:
  - sing-box
  - mac
  - nix
  - review
---

:::tip[TLDR]

这是上一篇
[《sing-box 在 macOS 唤醒后长时间断网问题的诊断和fix》](2026-03-20-singbox-darwin-wake-recovery.md)
的后续。

这次最后确认下来，主因还是 `sing-box` 的配置，不是 wake recover script。

---

做了以下修改项

```yaml
- `default_domain_resolver = "local"`
- `remote` 改回 `223.5.5.5 + detour=select`
- 去掉显式 `tun-in -> select`
- 关闭 `reverse_mapping`
```

彻底解决问题

**_可以看到核心在于DNS server 修改为 223.5.5.5，并设置 `default_domain_resolver` 为 local_**

具体查看

[fix/singbox-darwin-rollback by xbpk3t · Pull Request #26 · xbpk3t/dotfiles](https://github.com/xbpk3t/dotfiles/pull/26)

:::

## 起因

在使用了上面的 wakeup recover script 方案后，“开盖后断网”问题就已经暂时解决了。但是会有偶发的高CPU占用（sing-box的 `%CPU` 显示为 541%，也就是5个半核心都在跑sing-box，很明显是CPU占用异常），导致CPU温度很高（80度），尝试让 codex 帮我排查，但是也是千头万绪，难以定位。想了一下之前用机场的sing-box配置都没出过问题，大概率还是我自己sing-box配置的问题。

随手找了一个之前用的机场sing-box配置，根本的 `/run/sing-box/config.json` 对比了一下发现，归根到底还是 DNS是否为local的问题

<details>
<summary>机场singbox的config.json</summary>

```json
{
  "dns": {
    "fakeip": {
      "enabled": true,
      "inet4_range": "198.18.0.0/15",
      "inet6_range": "fc00::/18"
    },
    "independent_cache": true,
    "rules": [
      {
        "outbound": ["any"],
        "server": "local"
      },
      {
        "disable_cache": true,
        "rule_set": ["AdGuardSDNSFilter", "chrome-doh"],
        "server": "block"
      },
      {
        "query_type": ["A", "AAAA"],
        "rewrite_ttl": 1,
        "server": "fakeip"
      },
      {
        "clash_mode": "global",
        "server": "remote"
      },
      {
        "clash_mode": "direct",
        "server": "local"
      },
      {
        "rule_set": "geosite-cn",
        "server": "local"
      }
    ],
    "servers": [
      {
        "address": "https://223.5.5.5/dns-query",
        "detour": "select",
        "tag": "remote"
      },
      {
        "address": "https://223.5.5.5/dns-query",
        "detour": "direct",
        "tag": "local"
      },
      {
        "address": "rcode://success",
        "tag": "block"
      },
      {
        "address": "fakeip",
        "tag": "fakeip"
      }
    ],
    "strategy": "prefer_ipv4"
  },
  "experimental": {
    "cache_file": {
      "enabled": true
    },
    "clash_api": {
      "external_controller": "127.0.0.1:9090",
      "secret": ""
    }
  },
  "inbounds": [
    {
      "address": ["172.19.0.1/30", "fdfe:dcba:9876::1/126"],
      "auto_route": true,
      "endpoint_independent_nat": true,
      "mtu": 9000,
      "strict_route": true,
      "type": "tun"
    },
    {
      "listen": "127.0.0.1",
      "listen_port": 2333,
      "tag": "socks-in",
      "type": "socks",
      "users": []
    },
    {
      "listen": "127.0.0.1",
      "listen_port": 2334,
      "tag": "mixed-in",
      "type": "mixed",
      "users": []
    }
  ],
  "log": {},
  "outbounds": [
    {
      "tag": "select",
      "type": "selector",
      "default": "urltest",
      "outbounds": ["urltest"]
    },
    {
      "tag": "urltest",
      "type": "urltest",
      "outbounds": []
    },

    {
      "tag": "direct",
      "type": "direct"
    }
  ],
  "route": {
    "auto_detect_interface": true,
    "rule_set": [
      {
        "format": "binary",
        "tag": "geoip-cn",
        "type": "remote",
        "url": "http://sbx.lmd1n2s3.cc:21088/sbx/geoip-cn.srs",
        "download_detour": "direct"
      },
      {
        "format": "binary",
        "tag": "geosite-cn",
        "type": "remote",
        "url": "http://sbx.lmd1n2s3.cc:21088/sbx/geosite-geolocation-cn.srs",
        "download_detour": "direct"
      },
      {
        "format": "binary",
        "tag": "AdGuardSDNSFilter",
        "type": "remote",
        "url": "http://sbx.lmd1n2s3.cc:21088/sbx/AdGuardSDNSFilterSingBox.srs",
        "download_detour": "direct"
      },
      {
        "format": "source",
        "tag": "chrome-doh",
        "type": "remote",
        "url": "http://sbx.lmd1n2s3.cc:21088/sbx/chrome-doh.json",
        "download_detour": "direct"
      }
    ],
    "rules": [
      {
        "action": "sniff"
      },
      {
        "action": "hijack-dns",
        "protocol": "dns"
      },
      {
        "action": "resolve",
        "strategy": "prefer_ipv4"
      },
      {
        "clash_mode": "direct",
        "outbound": "direct"
      },
      {
        "clash_mode": "global",
        "outbound": "select"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      },
      {
        "outbound": "direct",
        "rule_set": "geoip-cn"
      }
    ]
  }
}
```

其实这个没有参考性，sing-box v1.12 之后很多语法都不支持了

</details>

## 具体做了哪些修改

:::tip

基于以上的分析，首先肯定是把 `darwin/singbox-client.nix` 的 `recover script` 移除掉，恢复之前的方案，这点不多说。

核心还是对于singbox本身的调整。

:::

这次最终有效的核心，其实就一句话：

> bootstrap 走 local，foreign 仍走 remote。

它的旧写法大概是这样：

```json title="sing-box/config.json"
{
  "outbound": ["any"],
  "server": "local"
}
```

这条规则在新版本 sing-box 里已经废弃了，不能直接照抄。但它表达的意思很重要：

> 先保证 DNS bootstrap 可用，再让真正的 foreign 解析按代理链走。

### DNS

#### 核心修改：`remote` 回到旧机场的模型

这次最有效的修改，其实是把 `remote` 改回更接近旧机场配置的写法。

最终保留的是：

```nix title="lib/singbox/dns.nix"
{
  type = "https";
  tag = "local";
  server = "223.5.5.5";
  path = "/dns-query";
}
{
  type = "https";
  tag = "remote";
  server = "223.5.5.5";
  path = "/dns-query";
  detour = "select";
}
```

这里和我之前那版最大的区别是：

- 不再让 `remote` 用 `1.1.1.1`
- 而是让 `local` 和 `remote` 共享同一个 upstream：`223.5.5.5`
- 二者的差别只保留在 `detour`

这个变化看起来反直觉，但对 `sleep/wake` 场景反而更稳。

因为 wake 之后，系统要恢复的链路越短越好。
如果 `local` 和 `remote` 同时在 upstream 和 detour 两层都分叉，那恢复时序就更脆。

旧机场配置更保守，但事实证明它在这里是对的。

#### `dns.final` 还是 `remote`

我前面试错里最明显的一步，就是把 `dns.final = "remote"` 改成了 `local`。结果也很直接：

- 国内网站可用
- 国外网站不通

这个结果反过来也说明，`dns.final` 不能乱改。

最终保留的是这段：

```nix title="lib/singbox/dns.nix"
independent_cache = true;
reverse_mapping = false;
final = "remote";
strategy = "prefer_ipv4";
```

这里 `final = "remote"` 的意义很简单：foreign domains 在未命中规则时，最终仍然走 remote，而不是掉回本地 upstream。

### route

#### `default_domain_resolver = "local"`

```nix title="lib/singbox/route.nix"
{
  auto_detect_interface = true;
  final = "select";
  default_domain_resolver = "local";

  rules = [
    {
      action = "sniff";
    }
    {
      action = "hijack-dns";
      protocol = "dns";
    }
    {
      protocol = [ "bittorrent" "ssh" "rdp" "ntp" ];
      action = "route";
      outbound = "direct";
    }
    {
      ip_is_private = true;
      action = "route";
      outbound = "direct";
    }
    {
      rule_set = "geoip-cn";
      outbound = "direct";
    }
    {
      rule_set = [ "geosite-geolocation-cn" "geosite-steam" ];
      outbound = "direct";
    }
    {
      action = "resolve";
      strategy = "prefer_ipv4";
    }
  ];
}
```

这里 `default_domain_resolver = "local"` 很关键。它不是让 foreign 域名都走本地 DNS，而是在最底层给整个 DNS bootstrap 一个稳定的本地 resolver。

#### 去掉那条更激进的 TUN 兜底

我最后还去掉了这条 route：

```nix
{
  inbound = [ "tun-in" ];
  outbound = "select";
}
```

原因不复杂。`route.final = "select"` 已经能表达默认出站了，再显式加一条 `tun-in -> select`，只会让所有剩余 TUN 流量更早、更强地依赖代理链。

而 wake recovery 初期，最脆弱的恰恰就是这条链。

所以这一刀虽然不如 DNS 那几处关键，但也确实有帮助。

## 反思

现在回头看，上一篇文章的问题不是“完全错了”，而是停得太早。

上一篇为什么会得出“需要 wake recover script”这个判断，其实很自然，因为当时的证据确实是：

- `launchd` 还在
- sing-box 进程还活着
- 手动 `kickstart -k` 后网络就恢复

只看这些现象，很容易得出结论：

> 静态配置没问题，问题在 wake 后运行态和系统网络态失同步。

这个判断在当时看起来是合理的。问题在于，它把“恢复动作有效”误当成了“根因不在配置”。

而这次重新从 CPU 异常开始查，顺着旧机场 `config.json` 对照下去，最后反而把真正的问题又找回到了 `sing-box` 配置本身。

所以更准确的说法应该是：

- 上一篇记录的是一个有效的 workaround
- 这一次找到的是更接近根因的修复

这两件事不完全矛盾，但显然后者更重要。

---

# 结论

:::danger

现在来看，之前确实是误判了

更多是把“快速止血操作”当成了彻底解决问题的方案（核心在于FOMO，以为mac上的sing-box确实会出现这样的gotchas，但是心里肯定始终隐约觉得不对劲）

这次从异常 CPU 占用继续往下查，再对照机场配置，最后把问题重新收敛回了 `sing-box` 本身的 `DNS/route`问题。而这点是本就早应该发现的。因为现在来看，之前就发现了，每次休眠断网后，都要手动执行以下操作，就可以恢复正常，那么很明显就是sing-box的DNS设置问题，那么很明显就应该直接去调整 `DNS resolver`就好了，那么也就不需要绕这么一大圈，才能解决这么个小问题了。

---

最后，还要吐槽个东西，其实这个东西很简单，但是具体排查时真的很痛苦，不得不说这点就是NixOS相对于Darwin的优势了，每次在mac上修改了这种由launchd跑的服务之后，都要再跑

```shell

sudo launchctl bootout system /Library/LaunchDaemons/local.singbox.tun.plist

sudo launchctl bootstrap system /Library/LaunchDaemons/local.singbox.tun.plist

sudo launchctl kickstart -k "system/local.singbox.tun"

```

这三条命令之后成功把新配置刷进去之后，才能判断是否真的可用了。就很麻烦，这个就耽误了不少时间。

:::
