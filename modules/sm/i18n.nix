# sm 轨 locale + timezone。
# 映射自 modules/nixos/kernel/i18n.nix，用 sm 能力面表达：
#   NixOS 的 i18n.defaultLocale → environment.variables（LANG/LC_*）
#   NixOS 的 time.timeZone      → environment.etc."timezone"（glibc 读取）
{ lib, timeMeta, ... }:
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

  # ── timezone：/etc/timezone 指向 zoneinfo（distro tzdata 读取）──
  # 对应 NixOS time.timeZone；用 sm 的 hostMeta.time 传递时区。
  # 注意：environment.etc 需要真实文件；用 symlink 需要特殊处理。
  # 这里用 text 写入时区名（tzdata 通过 /etc/localtime 或 TZ 环境变量生效，
  # 由 distro 的 tzdata 包管理；VPS 通常已在 cloud-init 设好）。
  environment.etc."timezone".text = lib.mkDefault timeMeta.timeZone;
}
