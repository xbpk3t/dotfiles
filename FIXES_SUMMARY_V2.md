# 问题修复总结 V2 - 基于实际服务器诊断

## 修复时间
2025-10-11 (更新版)

## 实际问题诊断

通过 SSH 到服务器 `luck@192.168.234.194` 进行了详细诊断，发现以下实际情况：

### 当前状态
1. **系统最后重建时间**: 10月 6日（配置未更新）
2. **配置目录**: `/home/luck/Desktop/nix-config`（不是 `~/nix-config`）
3. **netbird 服务名称**: `netbird-.service`（有后缀）
4. **netbird socket 路径**: `/var/run/netbird-/sock`（CLI 期望 `/var/run/netbird/sock`）
5. **sing-box 服务**: 用户级服务已加载但启动失败

---

## 问题列表与修复方案

### 1. ✅ ugit 的 bat 错误（无需修复）

#### 问题描述
```
[bat error]: '1 Undo git commit': No such file or directory (os error 2)
```

#### 根本原因
这是 **ugit 本身的 bug**，不是配置问题。ugit 尝试将菜单文本传递给 bat 进行语法高亮。

#### 解决方案
**无需修复** - 虽然有错误提示，但 ugit 的所有功能都正常工作。

---

### 2. ✅ zellij 插件错误（已修复）

#### 问题描述
```
Error occurred in server:
  × Thread 'screen' panicked.
  failed to send message to plugin
```

#### 根本原因
配置中引用了不存在的 `zellij:filepicker` 插件。

#### 解决方案
从 `home/base/core/zellij.nix` 中移除了 filepicker 插件引用。

**修改文件**: `home/base/core/zellij.nix`

---

### 3. ✅ netbird 服务名称和 socket 路径问题（已修复）

#### 问题描述
1. 服务名称是 `netbird-.service` 而不是 `netbird.service`
2. Socket 路径是 `/var/run/netbird-/sock`
3. CLI 尝试连接 `/var/run/netbird/sock`，导致错误：
   ```
   dial unix /var/run/netbird/sock: connect: no such file or directory
   ```

#### 根本原因
在 `services.netbird.clients` 配置中：
- 使用了 attribute set key（如 "nixos-ws"）
- 即使设置 `name = ""`，NixOS 仍然使用 attribute key 作为后缀
- 导致服务名称变成 `netbird-{key}.service`

#### 解决方案

**修改文件**: `modules/nixos/base/networking/netbird.nix`

关键改进：
```nix
# 检测是否只有单个客户端
isSingleClient = (lib.length (lib.attrNames enabledClients)) == 1;

# 如果是单个客户端，将 attribute key 重命名为 "default"
finalOptions = if isSingleClient && (lib.length (lib.attrNames clientOptions) == 1)
  then { "default" = lib.head (lib.attrValues clientOptions); }
  else clientOptions;
```

**效果**:
- 单个客户端时：服务名称为 `netbird.service`，socket 为 `/var/run/netbird/sock`
- 多个客户端时：每个客户端有独立的服务名称和 socket

---

### 4. ✅ sing-box 服务启动失败（已修复）

#### 问题描述
```
FATAL[0000] start service: start inbound/tun[0]: configure tun interface: operation not permitted
```

用户级服务无法启动，退出码 1。

#### 根本原因
**你是对的！** sing-box 需要创建 TUN 接口，这需要 root 权限和 `CAP_NET_ADMIN` capability。

用户级服务（`systemd.user.services`）无法获得这些权限。

#### 解决方案

**修改文件**: `modules/nixos/base/networking/singbox.nix`

完全重写为系统级服务：

```nix
systemd.services.sing-box = {
  description = "Sing-box Proxy Service";
  wantedBy = [ "multi-user.target" ];
  after = [ "network.target" ];
  
  serviceConfig = {
    Type = "simple";
    ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${cfg.configPath}";
    Restart = "always";
    RestartSec = "5s";
    
    # Security hardening
    # Allow CAP_NET_ADMIN for TUN interface creation
    AmbientCapabilities = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
    CapabilityBoundingSet = "CAP_NET_ADMIN CAP_NET_BIND_SERVICE";
    
    # Run as root (required for TUN)
    User = "root";
    
    # Additional security
    NoNewPrivileges = false;  # Must be false for capabilities
    ProtectSystem = "strict";
    ProtectHome = "read-only";  # Need to read config from /home
    PrivateTmp = true;
  };
};
```

**关键改进**:
1. 改为系统级服务（`systemd.services`）
2. 以 root 身份运行（TUN 接口需要）
3. 添加必要的 capabilities（`CAP_NET_ADMIN`）
4. 保持安全加固（`ProtectSystem`, `ProtectHome`, `PrivateTmp`）
5. 配置文件路径可配置，默认 `/home/luck/config.json`

---

## 部署步骤

### 方法 1: 使用自动部署脚本（推荐）

```bash
cd /Users/lhgtqb7bll/Desktop/nix-config
./deploy-fixes.sh
```

### 方法 2: 手动部署

```bash
# 1. 在本地提交更改
cd /Users/lhgtqb7bll/Desktop/nix-config
git add -A
git commit -m "fix: resolve zellij, netbird, and sing-box issues"
git push

# 2. SSH 到服务器
ssh luck@192.168.234.194
# 密码: 159357

# 3. 拉取并重建
cd ~/Desktop/nix-config
git pull
sudo nixos-rebuild switch --flake .#nixos-ws

# 4. 验证
systemctl status netbird.service
netbird status
systemctl status sing-box.service
zellij --version
```

---

## 验证步骤

### 验证 netbird

```bash
# 检查服务名称（应该是 netbird.service）
systemctl status netbird.service

# 检查 socket 路径
ls -la /var/run/netbird/

# 测试 CLI 连接
netbird status

# 登录（如果需要）
netbird login
```

### 验证 sing-box

```bash
# 检查系统服务状态
systemctl status sing-box.service

# 查看日志
journalctl -u sing-box.service -f

# 检查进程
ps aux | grep sing-box

# 测试网络连接
curl -I https://www.google.com
```

### 验证 zellij

```bash
# 启动 zellij
zellij

# 应该正常启动，不再有插件错误
# 按 Ctrl+q 退出
```

---

## 预期结果

### ✅ netbird
- 服务名称: `netbird.service`
- Socket 路径: `/var/run/netbird/sock`
- CLI 命令: `netbird status`, `netbird login` 正常工作
- 日志中不再有 "no peer auth method" 错误（登录后）

### ✅ sing-box
- 服务名称: `sing-box.service`（系统级）
- 服务状态: `active (running)`
- 配置文件: `/home/luck/config.json`
- TUN 接口: 成功创建
- 代理功能: 正常工作

### ✅ zellij
- 正常启动，不再崩溃
- 显示 tab-bar 和 status-bar
- 可以正常创建和管理窗格

### ⚠️ ugit
- 功能正常，但会显示 bat 错误提示
- 这是上游问题，不影响使用

---

## 技术细节

### netbird 服务命名机制

NixOS 的 `services.netbird.clients` 使用 attribute set：

```nix
services.netbird.clients = {
  "client-name" = { ... };  # 生成 netbird-client-name.service
  "default" = { ... };      # 生成 netbird.service
};
```

**关键点**:
- 使用 "default" 作为 key 可以得到默认服务名 `netbird.service`
- 其他任何 key 都会作为后缀添加到服务名中

### sing-box TUN 接口权限

TUN 接口创建需要：
1. **Root 权限** 或 **CAP_NET_ADMIN** capability
2. 用户级服务无法获得这些权限
3. 必须使用系统级服务

**安全考虑**:
- 虽然以 root 运行，但通过 systemd 的安全特性进行了加固
- `ProtectSystem=strict`: 只读文件系统
- `ProtectHome=read-only`: 只读 home 目录
- `PrivateTmp=true`: 私有临时目录
- `CapabilityBoundingSet`: 限制只有必要的 capabilities

---

## 后续优化建议

### 1. netbird 自动登录
考虑使用 setup key 实现自动登录：
```nix
# 在配置中添加 setup key（使用 sops-nix 加密）
```

### 2. sing-box 配置管理
实现从 sub-store URL 自动拉取配置：
```nix
# 添加定时任务自动更新配置
systemd.timers.sing-box-update-config = { ... };
```

### 3. zellij 插件
如果需要文件选择功能，可以：
- 研究正确的插件安装方法
- 或使用 `zellij-org/awesome-zellij` 中的其他插件

### 4. 监控和告警
添加服务监控：
```nix
# 使用 systemd 的 OnFailure 发送告警
systemd.services.sing-box.serviceConfig.OnFailure = "notify-admin.service";
```

---

## 故障排查

### 如果 netbird CLI 仍然无法连接

```bash
# 检查 socket 路径
ls -la /var/run/netbird*

# 检查服务日志
journalctl -u netbird.service -f

# 重启服务
sudo systemctl restart netbird.service
```

### 如果 sing-box 无法启动

```bash
# 检查配置文件
sing-box check -c /home/luck/config.json

# 查看详细日志
journalctl -u sing-box.service -n 100 --no-pager

# 测试手动运行
sudo sing-box run -c /home/luck/config.json
```

### 如果 zellij 仍然崩溃

```bash
# 查看日志
cat /tmp/zellij-*/zellij-log/zellij.log

# 清除缓存
rm -rf ~/.cache/zellij

# 重新生成配置
zellij setup --dump-config > ~/.config/zellij/config.kdl
```

