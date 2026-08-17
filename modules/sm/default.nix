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
{ ... }:
{
  _file = ./default.nix;

  imports = [
    ./packages.nix
    ./managed-flag.nix
    ./sshd.nix
    ./nix-conf.nix
    ./tailscale.nix
    ./sops.nix
    ./systemd.nix
    ./i18n.nix
    ./shells.nix
    ./gc.nix
    ./mihomo.nix
    ./fail2ban.nix
    ./sudoers.nix
    ./singbox.nix
    ./firewall.nix
    ./derper.nix
  ];
}
