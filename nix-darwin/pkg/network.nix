{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # 网络工具
    wget
    curl
    mosh
    fping
    nmap
    inetutils
    # libpcap
    # sshpass

    # 网络安全
    subfinder

    # 性能测试
    # vegeta
    # speedtest-cli

    # 云存储和同步
    rclone

    # 下载工具
    aria2 # A lightweight multi-protocol & multi-source command-line download utility
    socat # replacement of openbsd-netcat
  ];
}
