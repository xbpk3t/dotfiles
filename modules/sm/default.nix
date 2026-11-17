# sm 轨 system-manager 模块树（与 modules/nixos/** 分树；禁止 import nixos 模块）。
# 命名对齐：modules/{nixos,darwin,sm} 三轨平台，sm = 非 NixOS Linux 的系统管理面。
# 组织：按能力分文件。
#   - 基线能力（sops/sshd/systemd/i18n/tailscale）：模块暴露 modules.sm.*.enable，由 host 显式开启。
#   - 服务角色（mihomo-client/singbox-server）：各模块声明 services.*.enable 开关。
# hostPlatform / allowAnyDistro 由 lib/mkHost.nix 显式设置。
#
# ⚠️ 通用坑：environment.etc 对「已存在的 unmanaged 路径」默认静默跳过
# （激活日志 "Unmanaged path already exists"，需 replaceExisting=true 才覆盖；
# timezone 就是栽在这个坑上——声明了但没生效，见 i18n.nix）。
# 因此：声明任何 distro 已存在的路径（/etc/timezone、/etc/localtime、/etc/shells、
# /etc/nftables.conf、/etc/ssh/ssh_config 等）都必须显式 replaceExisting=true。
{
  config,
  lib,
  ...
}:
{
  _file = ./default.nix;

  # 共享机（shared=true）裁剪：基线能力按 host 显式选择。
  # shared 是 host 自己的策略（hosts/sm-vps/hk/default.nix 设置），
  # 不再由 outputs 透传 specialArg；各模块读 config.modules.sm.shared。
  options.modules.sm.shared = lib.mkEnableOption ''
    shared-host mode: disable global side effects that would affect other tenants
    (system sops, sshd hardening drop-in, userborn)
  '';

  # userborn 会重写 /etc/passwd 并把 root shell 指向 store bash，共享机上会
  # 影响其他租户；由 shared 统一定义，host 不需要再记一条手写开关。
  config = lib.mkIf config.modules.sm.shared {
    # 普通优先级覆盖 system-manager 的 mkDefault true。
    services.userborn.enable = false;
  };

  # 全部模块常驻 import（option 声明永远存在）：
  #   - 命名统一为 modules.* 布局（对齐 darwin/nixos 轨）：
  #       modules.networking.* — 客户端（mihomo）
  #       modules.infra.*       — 服务端/服务角色（singbox-server/derper/status-page）
  #   - shared 差异收敛到「config 主体」：各模块内部用
  #     lib.mkIf (!config.modules.sm.shared) / lib.mkIf (config ? sops)
  #     门控依赖 sops/tailscale 的部分，shared 下不求值。
  #   - system-manager 的 option 存在性检查不解析 mkIf 条件（定义无论真假都会注册），
  #     因此 option 必须常驻；hosts 文件的 enable 开关也统一 modules.* 命名。
  imports = [
    ./packages.nix
    ./managed-flag.nix
    ./sshd.nix
    ./nix-conf.nix
    ./systemd.nix
    ./i18n.nix
    ./shells.nix
    ./gc.nix
    ./fail2ban.nix
    ./sudoers.nix
    ./firewall.nix
    ./sops.nix
    ./mihomo.nix
    ./tailscale.nix
    ./singbox.nix
    ./derper.nix
    ./status-page.nix
  ];
}
