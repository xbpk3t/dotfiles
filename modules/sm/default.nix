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
  lib,
  isShared ? false,
  ...
}:
{
  _file = ./default.nix;

  # 共享机（shared=true）裁剪：基线能力按 host 显式选择。
  # 设计：isShared 由 outputs/.../sm-vps.nix 透传（node.shared 派生），
  # 各模块内用 lib.mkIf (!isShared) 关闭影响他人的全局副作用。
  # 这里不额外声明选项；各模块自行读 isShared。

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
    ./singbox.nix
    ./firewall.nix
    ./derper.nix
    ./status-page.nix
  ]
  ++ lib.optionals (!isShared) [
    # sops.nix：系统 sops（root secrets）。shared 不放主 key → 整个模块不 import。
    # mihomo.nix：无条件引用 sops.templates，shared 无 sops → 也不 import。
    # tailscale.nix：shared 不上 tailnet（避免开全局转发 + advertising exit node）。
    ./sops.nix
    ./mihomo.nix
    ./tailscale.nix
  ];
}
