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

    # TODO 1、用这几个工具跑一下现有的nix配置文件。2、做到Taskfile.nix.yml以及pre-commit里面
    deadnix # https://github.com/astro/deadnix
    nixpkgs-hammering # https://github.com/jtojnar/nixpkgs-hammering
    statix # https://github.com/oppiliappan/statix
    nixpkgs-lint-community # https://github.com/nix-community/nixpkgs-lint


    # zzz
    atuin
  ];
}
