{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # 网络工具 (excluding wget/curl which are in minimal)
    mosh
    fping
    nmap
    inetutils
    mtr
    nexttrace # 可视化路由跟踪工具

    # disk
    ncdu

    # 网络安全
    subfinder
    naabu # https://github.com/projectdiscovery/naabu 端口扫描工具

    # 性能测试
    # vegeta
    # speedtest-cli

    # 云存储和同步
    rclone

    deadnix # https://github.com/astro/deadnix
    statix # https://github.com/oppiliappan/statix

    # zzz
    atuin
  ];
}
