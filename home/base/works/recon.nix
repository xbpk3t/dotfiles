{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    # 信息收集
    nmap

    # 端口扫描工具
    naabu

    # 内网扫描工具
    fscan

    subfinder

    httpx

    dnsx
    gau
  ];
}
