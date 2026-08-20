# sm 轨 system-manager 模块树（与 modules/nixos/** 分树；禁止 import nixos 模块）。
# 命名对齐：modules/{nixos,darwin,sm} 三轨平台，sm = 非 NixOS Linux 的系统管理面。
# 组织：按能力分文件。
#   - 基线能力（sops/sshd/systemd/i18n/tailscale）：模块内直接 enable，不配置化。
#   - 服务角色（mihomo-client/singbox-server）：各模块声明 services.*.enable 开关。
# hostPlatform / allowAnyDistro 由 outputs/.../sm-vps.nix 显式设置。
#
# ⚠️ 通用坑：environment.etc 对「已存在的 unmanaged 路径」默认静默跳过
# （激活日志 "Unmanaged path already exists"，需 replaceExisting=true 才覆盖；
# timezone 就是栽在这个坑上——声明了但没生效，见 i18n.nix）。
# 因此：声明任何 distro 已存在的路径（/etc/timezone、/etc/localtime、/etc/shells、
# /etc/nftables.conf、/etc/ssh/ssh_config 等）都必须显式 replaceExisting=true。
{
  ...
}:
{
  _file = ./default.nix;

  # 共享机（shared=true）裁剪：基线能力按 host 显式选择。
  # 设计：isShared 由 outputs/.../sm-vps.nix 透传（node.shared 派生），
  # 各模块内用 lib.mkIf (!isShared) 关闭影响他人的全局副作用。
  # 这里不额外声明选项；各模块自行读 isShared。

  # 全部模块常驻 import（option 声明永远存在）：
  #   - 命名统一为 modules.* 布局（对齐 darwin/nixos 轨）：
  #       modules.networking.* — 客户端（mihomo）
  #       modules.infra.*       — 服务端/服务角色（singbox-server/derper/status-page）
  #   - isShared 差异收敛到「config 主体」：各模块内部用 lib.mkIf (!isShared) /
  #     lib.mkIf (config ? sops) 门控依赖 sops/tailscale 的部分，shared 下不求值。
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
