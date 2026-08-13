# sm 轨 Nix store GC（Determinate Nix 安装器不带自动 GC）。
# nixos 轨 nix.gc 的 sm 对应物：systemd oneshot + timer 每周回收 8 天前的旧
# generation 与死路径（--delete-older-than 8d 比 nix-collect-garbage -d 温和，
# 保留回滚余量）。nix 二进制用 nixpkgs 的 pkgs.nix，经 daemon socket 与
# Determinate nix-daemon 通信（协议兼容）。
#
# 这是 sm-vps 基线能力（防止 /nix/store 无限增长），不做配置化开关。
# 对抗式审查 N1：8.4G store / 2490 死路径 / 无任何自动回收。
{ pkgs, ... }:
{
  _file = ./gc.nix;

  systemd.services.sm-nix-gc = {
    description = "Nix store garbage collection (weekly, keep 8d)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 8d";
    };
  };

  # sm 引擎把 timers.target 映射到 system-manager.target（见上游 systemd.nix），
  # 计时器随系统正常运行时按 OnCalendar 触发。
  systemd.timers.sm-nix-gc = {
    description = "Weekly Nix store GC";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
