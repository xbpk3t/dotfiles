# Sing-Box项目NixOS-VPS集成路线图

## 集成策略总览

### 集成顺序确认
按照 **233boy → YG → v2ray-agent** 的顺序是正确的，原因：

1. **233boy/sing-box**: 极简架构，核心功能清晰，适合作为NixOS基础
2. **sing-box-yg**: 在233boy基础上扩展高级功能，增强用户体验
3. **v2ray-agent**: 企业级功能，用于完善生产环境管理

### 233boy项目核心功能识别

`★ Insight ─────────────────────────────────────`
• 233boy项目中很多VPS优化（如BBR、防火墙等）在NixOS中已有原生实现
• 真正需要服务化的是sing-box代理核心功能和配置管理
• NixOS的优势在于可以用声明式配置替代命令式脚本
`─────────────────────────────────────────────────`

#### 需要NixOS服务化的核心功能
1. **sing-box服务管理** - systemd服务，配置文件生成
2. **协议配置生成** - VLESS-REALITY, TUIC, Trojan, Hysteria2等
3. **TLS证书管理** - 通过NixOS的ACME集成
4. **配置快速操作** - 类似`sing-box add vless auto`的Nix函数
5. **客户端信息生成** - 二维码、分享链接等

#### NixOS原生替代的VPS优化功能
```nix
# 这些功能不需要额外服务化，NixOS原生支持
{
  # BBR优化 → NixOS networking.bbr.enable
  networking.bbr.enable = true;

  # 防火墙管理 → NixOS networking.firewall
  networking.firewall.enable = true;

  # 系统优化 → NixOS boot.kernel.sysctl
  boot.kernel.sysctl = {
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
  };

  # 用户管理 → NixOS users.users
  users.users.proxy = {
    isNormalUser = true;
    extraGroups = [ "sing-box" ];
  };
}
```

## 详细集成路线图

### 阶段1: 233boy核心功能集成 (2-3周)

#### 1.1 基础NixOS模块 (1周)
```nix
# modules/sing-box/default.nix - 核心模块结构
{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.sing-box;
in {
  options.services.sing-box = {
    enable = mkEnableOption "sing-box service";

    package = mkOption {
      type = types.package;
      default = pkgs.sing-box;
      description = "sing-box package to use";
    };

    # 基于233boy的协议配置
    configs = mkOption {
      type = types.attrsOf (types.submodule {...});
      default = {};
      description = "sing-box configuration profiles";
    };
  };

  config = mkIf cfg.enable {
    # systemd服务定义
    systemd.services.sing-box = {...};

    # 配置文件生成
    environment.etc."sing-box/config.json".text = {...};
  };
}
```

**任务清单**:
- [ ] 创建基础NixOS模块结构
- [ ] 实现systemd服务配置
- [ ] 设计配置文件生成逻辑
- [ ] 添加基本的错误处理

#### 1.2 协议配置生成 (1周)
```nix
# 协议配置生成器
{
  # VLESS-REALITY配置 (233boy默认)
  configs.vless-reality = {
    protocol = "vless";
    reality = true;
    port = 443;
    domain = "www.bing.com";
    auto = true;  # 自动生成UUID和参数
  };

  # TUIC配置
  configs.tuic = {
    protocol = "tuic";
    port = 10086;
    auto = true;
  };

  # Hysteria2配置
  configs.hysteria2 = {
    protocol = "hysteria2";
    port = 10087;
    auto = true;
  };
}
```

**任务清单**:
- [ ] 实现VLESS-REALITY配置生成
- [ ] 添加TUIC协议支持
- [ ] 集成Hysteria2配置
- [ ] 实现参数自动生成逻辑

#### 1.3 快速操作接口 (0.5周)
```nix
# 类似233boy的快速操作
{
  # 快速添加配置的Nix函数
  environment.shellAliases = {
    sb-add = "nixos-rebuild switch --option eval-cache false";
    sb-list = "cat /etc/sing-box/configs.json";
    sb-qr = "qrencode -t UTF8 $(cat /etc/sing-box/urls/vless.txt)";
  };

  # 管理脚本
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "sing-box-nix" ''
      # 模拟233boy的命令行接口
      case $1 in
        add) echo "Adding config: $2" ;;
        list) cat /etc/sing-box/configs.json ;;
        qr) qrencode -t UTF8 "$2" ;;
      esac
    '')
  ];
}
```

**任务清单**:
- [ ] 创建命令行管理脚本
- [ ] 实现配置列表功能
- [ ] 添加二维码生成功能
- [ ] 集成配置验证逻辑

#### 1.4 TLS证书集成 (0.5周)
```nix
# 使用NixOS原生ACME替代Caddy
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@example.com";

    certs."your-domain.com" = {
      webroot = "/var/lib/acme/challenges";
      postRun = "systemctl reload sing-box";
    };
  };

  # sing-box证书配置
  services.sing-box.tls = {
    enable = true;
    certFile = "/var/lib/acme/your-domain.com/cert.pem";
    keyFile = "/var/lib/acme/your-domain.com/key.pem";
  };
}
```

**任务清单**:
- [ ] 配置NixOS ACME证书申请
- [ ] 集成证书到sing-box配置
- [ ] 实现证书自动续期
- [ ] 测试TLS功能正常工作

### 阶段2: YG项目高级功能集成 (3-4周)

#### 2.1 多协议共存 (1.5周)
```nix
# 基于YG项目的四协议共存
{
  services.sing-box = {
    multiProtocol = {
      enable = true;

      # 自动端口分配，避免冲突
      protocols = {
        vless-reality = { port = 2001; };
        vmess-ws = { port = 2002; };
        hysteria2 = { port = 2003; };
        tuic5 = { port = 2004; };
      };

      # 统一的客户端配置生成
      unifiedConfig = true;
    };
  };
}
```

**任务清单**:
- [ ] 实现多协议同时运行配置
- [ ] 添加端口自动分配逻辑
- [ ] 确保协议间不冲突
- [ ] 生成统一的客户端配置

#### 2.2 双证书系统 (1周)
```nix
# YG项目的自签证书+ACME证书切换
{
  services.sing-box = {
    certificates = {
      # 自签证书 (YG默认)
      selfSigned = {
        enable = true;
        domain = "www.bing.com";
        generateWithNix = true;
      };

      # ACME证书 (可选)
      acme = {
        enable = false;
        domain = "your-domain.com";
        provider = "letsencrypt";
      };

      # 证书切换逻辑
      switchMode = "selfSigned"; # "selfSigned" | "acme"
    };
  };
}
```

**任务清单**:
- [ ] 实现自签证书生成
- [ ] 添加ACME证书支持
- [ ] 创建证书切换机制
- [ ] 测试两种证书模式

#### 2.3 WARP分流集成 (1周)
```nix
# YG项目的WARP分流功能Nix化
{
  services.sing-box = {
    warpIntegration = {
      enable = true;

      # IPv4/IPv6分流配置
      ipv4Outbound = true;
      ipv6Outbound = true;

      # 分流规则
      routing = {
        geoip = "/etc/sing-box/geoip.db";
        geosite = "/etc/sing-box/geosite.db";
        rules = [
          { type = "geoip"; outbound = "warp"; }
          { type = "default"; outbound = "proxy"; }
        ];
      };
    };

    # WireGuard接口配置 (WARP)
    networking.wireguard.interfaces.warp0 = {
      ips = [ "172.16.0.2/32" ];
      privateKey = "WARP_PRIVATE_KEY";

      peers = [{
        publicKey = "WARP_PUBLIC_KEY";
        endpoint = "162.159.192.1:2408";
        allowedIPs = [ "0.0.0.0/0" "::/0" ];
      }];
    };
  };
}
```

**任务清单**:
- [ ] 配置WireGuard WARP接口
- [ ] 实现分流规则生成
- [ ] 添加地理位置数据库支持
- [ ] 测试分流功能正确性

#### 2.4 Web管理界面 (0.5周)
```nix
# 基于YG项目的Web界面
{
  services.sing-box = {
    webInterface = {
      enable = true;
      port = 8080;

      # 简单的配置管理界面
      features = [
        "config-list"     # 配置列表
        "add-config"      # 添加配置
        "generate-qr"     # 生成二维码
        "export-config"   # 导出配置
      ];
    };
  };

  # Web界面服务
  systemd.services.sing-box-web = {
    description = "Sing-box Web Interface";
    after = [ "sing-box.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.nodejs}/bin/node web-server.js";
      WorkingDirectory = "/etc/sing-box/web";
    };
  };
}
```

**任务清单**:
- [ ] 创建Web界面服务
- [ ] 实现配置管理功能
- [ ] 添加二维码生成页面
- [ ] 集成配置导出功能

### 阶段3: v2ray-agent企业功能集成 (2-3周)

#### 3.1 用户管理系统 (1周)
```nix
# 基于v2ray-agent的用户管理
{
  services.sing-box = {
    userManagement = {
      enable = true;

      # 用户数据库
      users = [
        {
          name = "user1";
          uuid = "uuid-here";
          protocols = [ "vless" "vmess" ];
          limit = { bandwidth = "100GB"; devices = 3; };
        }
      ];

      # 用户隔离
      isolation = true;
    };
  };
}
```

**任务清单**:
- [ ] 设计用户数据结构
- [ ] 实现用户配置隔离
- [ ] 添加流量限制功能
- [ ] 创建用户管理工具

#### 3.2 订阅系统 (1周)
```nix
# v2ray-agent的订阅功能
{
  services.sing-box = {
    subscription = {
      enable = true;

      # 订阅服务器
      server = {
        port = 25500;
        path = "/sub";
        baseUrl = "https://your-domain.com";
      };

      # 订阅格式支持
      formats = [ "sing-box" "v2ray" "clash" ];

      # 自动更新间隔
      updateInterval = "1h";
    };
  };
}
```

**任务清单**:
- [ ] 实现订阅服务器
- [ ] 支持多种订阅格式
- [ ] 添加访问控制
- [ ] 测试订阅功能

#### 3.3 安全管理 (0.5周)
```nix
# v2ray-agent的安全功能
{
  services.sing-box = {
    security = {
      # 域名黑名单
      blockDomains = [
        "malware.com"
        "phishing-site.com"
      ];

      # P2P下载管控
      blockP2P = true;

      # 访问日志
      accessLog = true;
      logLevel = "info";
    };
  };
}
```

**任务清单**:
- [ ] 实现域名黑名单功能
- [ ] 添加P2P流量识别和阻止
- [ ] 配置访问日志记录
- [ ] 设置安全告警机制

#### 3.4 监控和统计 (0.5周)
```nix
# 监控和流量统计
{
  services.sing-box = {
    monitoring = {
      enable = true;

      # 流量统计
      trafficStats = true;

      # 性能监控
      performanceMonitor = true;

      # 健康检查
      healthCheck = {
        enable = true;
        interval = "30s";
        endpoint = "/health";
      };
    };
  };
}
```

**任务清单**:
- [ ] 实现流量统计收集
- [ ] 添加性能监控指标
- [ ] 配置健康检查端点
- [ ] 集成监控告警

### 阶段4: 测试和优化 (1-2周)

#### 4.1 全面测试
```bash
# 测试脚本
test-protocols() {
  # 测试所有协议连通性
  for config in vless vmess hysteria2 tuic; do
    echo "Testing $config..."
    # 连接测试
    # 延迟测试
    # 带宽测试
  done
}

test-security() {
  # 安全性测试
  # 匿名性检查
  # DNS泄露测试
}

test-performance() {
  # 性能压力测试
  # 并发连接测试
  # 长期稳定性测试
}
```

**任务清单**:
- [ ] 编写自动化测试脚本
- [ ] 执行协议连通性测试
- [ ] 进行安全性验证
- [ ] 性能压力测试

#### 4.2 文档和部署指南
```markdown
# NixOS Sing-Box部署指南

## 基础部署 (233boy功能)
## 高级功能部署 (YG功能)
## 企业功能部署 (v2ray-agent功能)
## 故障排除指南
```

**任务清单**:
- [ ] 编写部署文档
- [ ] 创建配置示例
- [ ] 制作故障排除指南
- [ ] 录制演示视频

## 实施时间表

| 阶段 | 功能 | 时间 | 优先级 |
|------|------|------|--------|
| 1 | 233boy核心功能 | 2-3周 | 🔴 高 |
| 2 | YG高级功能 | 3-4周 | 🟡 中 |
| 3 | v2ray-agent企业功能 | 2-3周 | 🟢 低 |
| 4 | 测试优化 | 1-2周 | 🔴 高 |

总计：**8-12周**完成完整集成

## 成功标准

### 阶段1成功标准
- [ ] 所有基础协议正常工作
- [ ] 配置生成和加载正确
- [ ] TLS证书自动申请和续期
- [ ] 基础管理功能可用

### 阶段2成功标准
- [ ] 四协议同时运行无冲突
- [ ] 双证书系统切换正常
- [ ] WARP分流功能正确
- [ ] Web界面可用

### 阶段3成功标准
- [ ] 用户管理系统完整
- [ ] 订阅系统功能正常
- [ ] 安全限制有效
- [ ] 监控统计数据准确

## 风险控制

### 技术风险
1. **配置复杂性** → 采用渐进式集成，先简后繁
2. **协议冲突** → 端口自动分配，配置隔离
3. **性能影响** → 模块化设计，按需启用功能

### 时间风险
1. **开发时间超期** → 分阶段交付，优先核心功能
2. **测试时间不足** → 并行开发和测试，自动化验证

### 维护风险
1. **项目更新** → 建立自动化同步机制
2. **版本兼容** → 锁定稳定版本，定期升级

`★ Insight ─────────────────────────────────────`
• 这个roadmap的核心是"渐进式集成"，每个阶段都有明确的交付目标
• 233boy阶段提供可用的基础功能，YG阶段增强用户体验，v2ray-agent阶段完善生产特性
• 模块化设计确保每个功能都可以独立启用和禁用，符合NixOS理念
`─────────────────────────────────────────────────`

## 下一步行动

建议立即开始**阶段1.1**：
1. 创建`modules/sing-box/`目录结构
2. 实现基础的systemd服务配置
3. 设计233boy风格的配置接口

这样可以在2-3周内获得一个可用的基础版本，然后逐步添加高级功能。