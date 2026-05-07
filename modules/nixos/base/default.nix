{
  mylib,
  pkgs,
  ...
}: {
  imports = mylib.scanPaths ./.;

  # MAYBE: [2026-04-19] 判断是否要添加
  # https://mynixos.com/nixpkgs/options/boot.initrd.systemd

  environment.systemPackages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/psmisc
    # https://gitlab.com/psmisc/psmisc
    # Install it for fuser
    psmisc

    # https://mynixos.com/nixpkgs/package/systemd-manager-tui
    # https://github.com/matheus-git/systemd-manager-tui
    # [2026-05-07] 比 systemctl-tui 好用
    systemd-manager-tui
  ];
}
