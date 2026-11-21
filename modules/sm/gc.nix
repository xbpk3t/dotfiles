# sm 轨 Nix store GC（Determinate Nix 安装器不带自动 GC）。
# nixos 轨 nix.gc 的 sm 对应物：systemd oneshot + daily timer，按数量保留最近
# 3 代（nix-env；profile 不存在时跳过），再按时间清 7 天前的旧 generation 和
# 死路径。nix 二进制用 nixpkgs 的 pkgs.nix，经 daemon socket 与 Determinate
# nix-daemon 通信（协议兼容）。
#
# 这是 sm-vps 基线能力（防止 /nix/store 无限增长）；由 hosts/sm-vps/default.nix 显式开启
# modules.sm.gc.enable。
# 对抗式审查 N1：8.4G store / 2490 死路径 / 无任何自动回收。
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.sm.gc;

  # system-manager 环境和 NixOS 不同；只有 profile 存在时才做 count prune，
  # 且失败不阻塞后面的 GC。
  pruneScript = pkgs.writeShellScript "sm-nix-prune-generations" ''
    set -eu
    if [ -e /nix/var/nix/profiles/system ]; then
      ${pkgs.nix}/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +3 || true
    fi
  '';
in
{
  _file = ./gc.nix;

  options.modules.sm.gc.enable = lib.mkEnableOption "Nix store GC timer (sm track)";

  config = lib.mkIf cfg.enable {
    systemd.services.sm-nix-gc = {
      description = "Nix store garbage collection (daily, keep last 3 generations + 7d)";
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = pruneScript;
        ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 7d";
      };
    };

    # sm 引擎把 timers.target 映射到 system-manager.target（见上游 systemd.nix），
    # 计时器随系统正常运行时按 OnCalendar 触发。
    systemd.timers.sm-nix-gc = {
      description = "Daily Nix store GC";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}
