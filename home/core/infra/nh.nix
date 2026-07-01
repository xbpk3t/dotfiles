{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.infra.nh;
in
{
  options.modules.infra.nh.enable = lib.mkEnableOption "Nix helper tools (nh, nvd, comma)";

  config = lib.mkIf cfg.enable {
    # Additional Nix management tools
    home.packages = with pkgs; [
      # nom
      nix-output-monitor
      nvd
      # Nix 死代码检查
      deadnix
      # [move history] 之前放在 hosts/nixos-vps，但 VPS 不需要这两个 pkg，所以放 homelab；
      # 之后因为可能也会用 mac 作为核心控制端，直接放到 base 来多端复用；
      # 现在放到 infra（Nix 生态工具的统一位置）。
      nixos-anywhere
      # 同上，目前仅 workstation 有必要引入
      deploy-rs

      # 云平台隧道工具
      cloudflared
      # HTTP CLI
      httpie
    ];

    # 把这些支持 HM 的 Nix 相关工具放在这里，以便 Darwin 和 NixOS 复用。
    programs = {
      nix-index = {
        enable = true;
      };

      nix-index-database = {

        comma = {
          # what: 让 `comma` 也复用 nix-index-database 提供的 wrapper。
          # why: 既然当前已经引入预生成 database，就顺手把 ad-hoc command lookup 统一到同一条索引链路，
          #      避免后面排查 `nix-locate` 和 `comma` 行为时出现两套数据来源。
          enable = true;
        };
      };
    };
  };
}
