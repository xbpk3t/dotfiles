{
  config,
  lib,
  pkgs,
  ...
}:
# https://nixos.wiki/wiki/Samba
let
  cfg = config.modules.homelab.samba;
in {
  options.modules.homelab.samba = {
    enable = lib.mkEnableOption "Enable Samba for homelab file sharing";

    shareName = lib.mkOption {
      type = lib.types.str;
      default = "luck";
      description = "SMB share name shown to clients.";
      # 统一入口名，方便在多客户端里稳定映射与书签化
    };

    sharePath = lib.mkOption {
      type = lib.types.path;
      default = "/home/luck";
      description = "Filesystem path to share over SMB.";
      # 明确共享范围，避免误共享更大的目录
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "luck";
      description = "Local user mapped to the Samba share.";
      # 绑定本地用户，确保文件属主和权限逻辑一致
    };

    password = lib.mkOption {
      type = lib.types.str;
      description = "Plaintext Samba password; move to sops later.";
      # 目前用明文便于快速可用，后续可切到密钥管理以降低泄露风险
    };

    allowedLan = lib.mkOption {
      type = lib.types.str;
      default = "192.168.71.0/24";
      description = "Allowed LAN CIDR for Samba access.";
      # 局域网白名单，默认拒绝非内网来源
    };

    allowedTailscaleIp = lib.mkOption {
      type = lib.types.str;
      default = "100.115.38.12/32";
      description = "Allowed Tailscale client IP/CIDR for Samba access.";
      # 允许特定内网穿透客户端，避免把 VPN 整段放开
    };
  };

  config = lib.mkIf cfg.enable {
    # https://mynixos.com/nixpkgs/options/services.samba
    services.samba = {
      enable = true;
      # 用用户级认证，避免匿名访问导致权限失控
      securityType = "user";

      settings = {
        global = {
          # 兼容老客户端的默认工作组名，减少发现障碍
          workgroup = "WORKGROUP";
          # 提示性名称，方便在网络浏览里识别服务器
          "server string" = "nixos-homelab";
          # 禁用 SMB1，降低已知安全风险
          "server min protocol" = "SMB2_10";
          # 保持较新协议上限，兼顾性能与兼容
          "server max protocol" = "SMB3_11";
          # 明确拒绝 guest，避免绕过认证
          "map to guest" = "never";

          # 白名单优先，缩小暴露面
          "hosts allow" = "127.0.0.1 ${cfg.allowedLan} ${cfg.allowedTailscaleIp}";
          # 默认拒绝所有，再用 allow 放行
          "hosts deny" = "0.0.0.0/0";

          # macOS Finder compatibility
          # 启用 macOS 兼容层，减少文件名/元数据问题
          "vfs objects" = "catia fruit streams_xattr";
          # 将元数据放在流里，避免生成额外文件
          "fruit:metadata" = "stream";
          # 提升 Finder 重命名行为兼容性
          "fruit:posix_rename" = "yes";
          # 允许 AppleDouble，避免 Finder 异常
          "fruit:veto_appledouble" = "no";
          # 规避 macOS 文件 ID 兼容问题
          "fruit:zero_file_id" = "yes";
          # 开扩展属性以支持 macOS 元数据
          "ea support" = "yes";
          # 保留 DOS 属性，避免权限/只读标记丢失
          "store dos attributes" = "yes";
        };

        "${cfg.shareName}" = {
          path = toString cfg.sharePath;
          # 允许网络浏览，便于客户端发现
          browseable = "yes";
          # 需要读写共享，避免权限限制
          "read only" = "no";
          # 只允许指定用户，降低误用
          "valid users" = cfg.user;
          # 统一文件属主，避免权限混乱
          "force user" = cfg.user;
          # 默认同组可写，便于多设备协作
          "create mask" = "0660";
          # 目录同组可进出，配合组权限管理
          "directory mask" = "0770";
        };
      };
    };

    # Store the SMB password locally; move to sops later.
    environment.etc."samba/${cfg.user}.pass".text = cfg.password; # 先落地文件便于服务引导时读入

    systemd.services.samba-password-ensure = {
      description = "Ensure Samba password for ${cfg.user}";
      wantedBy = ["multi-user.target"];
      after = ["samba-smbd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [
        pkgs.samba
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gawk
        pkgs.bash
      ];
      script = ''
        set -euo pipefail

        if ! pdbedit -L | awk -F: '{print $1}' | grep -qx "${cfg.user}"; then
          pass=$(cat /etc/samba/${cfg.user}.pass)
          printf '%s\n%s\n' "$pass" "$pass" | smbpasswd -a -s "${cfg.user}"
        fi
      '';
    };
  };
}
