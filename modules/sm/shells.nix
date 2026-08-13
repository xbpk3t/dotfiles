# sm 轨 /etc/shells：注册 luck 的 nix 登录 shell（zsh）。
# Debian 出厂 /etc/shells 不含 nix 的 zsh；usermod/chsh 对不在列表的 shell 会告警
# （usermod 仍生效、SSH 不受影响；chsh 则直接拒绝，HM 的 home.shell 若走 chsh 会失败）。
#
# 登录 shell 的声明化说明（对抗式审查 N4）：
# - HM 本版本的 home.shell 仅控制 shell 集成（rc 文件），不写 /etc/passwd；
# - userborn 直接管理 bootstrap 已建的 luck 用户风险高（可能重置 sudo 组、锁死 NOPASSWD）；
#   故登录 shell 仍由 deploy:sm 任务的 usermod 设置，这里只把 zsh 路径注册进合法 shell 列表。
{ userMeta, ... }:
let
  # 登录 shell 路径：由 userMeta 推导，避免硬编码 luck（对抗式审查低风险遗留）。
  shellPath = "/home/${userMeta.username}/.nix-profile/bin/zsh";
in
{
  _file = ./shells.nix;

  # replaceExisting：覆盖镜像出厂的 /etc/shells（内容镜像 Debian 默认 + zsh）。
  environment.etc."shells" = {
    text = ''
      # /etc/shells: valid login shells
      /bin/sh
      /usr/bin/sh
      /bin/bash
      /usr/bin/bash
      /bin/rbash
      /usr/bin/rbash
      /usr/bin/dash
      # nix home-manager profile 的 zsh（deploy:sm 的 usermod 所设登录 shell）
      ${shellPath}
    '';
    replaceExisting = true;
  };
}
