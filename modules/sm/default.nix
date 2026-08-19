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

  # ⚠️ 模块导入与 isShared（system-manager 的 option 存在性检查不解析 mkIf 条件，
  # 定义无论真假都会注册）：
  #   - 常驻组（下方）：option 永远存在（singbox/derper/status-page 用 mkEnableOption），
  #     config 内依赖 sops 的块用 lib.mkIf (config ? sops) 门控，shared 下不求值。
  #   - optionals (!isShared)：sops/tailscale/mihomo 的「配置主体」只在非共享机生效；
  #     sops.nix 整体不 import（其 option 消失），服务角色 config 有 sops 引用时
  #     借用 (config ? sops) 守卫避免未知属性。
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
    ./singbox.nix
    ./derper.nix
    ./status-page.nix
  ]
  ++ lib.optionals (!isShared) [
    # mihomo.nix / tailscale.nix — 非共享机才启用配置主体（见各自文件内部的
    # mkIf (!isShared) / 依赖 sops 的门控）；option 声明在常驻 import 里，shared 下
    # 依旧可引用（如 hosts 文件的 services.*.enable = mkIf (!isShared) ...）。
    ./mihomo.nix
    ./tailscale.nix
  ]
  # sops.nix 常驻：sops-nix 模块（声明 sops.* options）无条件 import——
  # shared 下 option 存在但配置为空（sops = mkIf (!isShared) {...}），
  # 服务角色模块的 config.sops.* 引用不会因 option 缺失而报错。
  ++ [ ./sops.nix ];
}
