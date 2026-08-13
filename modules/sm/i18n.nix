# sm 轨 locale + timezone。
# 映射自 modules/nixos/kernel/i18n.nix，用 sm 能力面表达：
#   NixOS 的 i18n.defaultLocale → environment.variables（LANG/LC_*）
#   NixOS 的 time.timeZone      → environment.etc."timezone"（glibc 读取）
#
# 这是 sm-vps 基线能力（locale/timezone 必需），不做配置化开关。
{ pkgs, timeMeta, ... }:
{
  _file = ./i18n.nix;

  # ── locale：en_US.UTF-8 ──
  environment.variables = {
    LANG = "en_US.UTF-8";
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };

  # ── timezone：Debian 实际生效靠 /etc/localtime（symlink），/etc/timezone 供 tzdata 工具读。
  # 镜像预置两者均为 Asia/Shanghai；但 sm 若只声明 /etc/timezone，激活时会被
  # "Unmanaged path already exists" 跳过 → 声明静默失效、改 config 不传播
  # （对抗式审查 N6 类，本轮实测确认）。因此：
  #   - /etc/timezone：replaceExisting 覆盖（text 写时区名）
  #   - /etc/localtime：显式指向 nix store 的 tzdata zoneinfo（replaceExisting 覆盖镜像 symlink）
  environment.etc."timezone" = {
    text = timeMeta.timeZone;
    replaceExisting = true;
  };
  environment.etc."localtime" = {
    source = "${pkgs.tzdata}/share/zoneinfo/${timeMeta.timeZone}";
    replaceExisting = true;
  };
}
