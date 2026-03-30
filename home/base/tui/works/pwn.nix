{
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs;
    [
      # 信息收集
      # https://github.com/nmap/nmap
      # https://mynixos.com/nixpkgs/package/nmap
      nmap

      # 渗透测试框架
      # https://github.com/rapid7/metasploit-framework
      # https://mynixos.com/nixpkgs/package/metasploit
      metasploit

      # 嗅探欺骗
      # https://github.com/Ettercap/ettercap
      # https://mynixos.com/nixpkgs/package/ettercap
      ettercap

      # 内网扫描工具
      # https://github.com/shadow1ng/fscan
      # https://mynixos.com/nixpkgs/package/fscan
      fscan

      # https://mynixos.com/nixpkgs/package/subfinder
      # https://github.com/projectdiscovery/subfinder
      subfinder

      # https://mynixos.com/nixpkgs/package/httpx
      # https://github.com/projectdiscovery/httpx
      httpx

      # 渗透测试
      # https://github.com/projectdiscovery/katana
      # https://mynixos.com/nixpkgs/package/katana
      katana

      # 漏洞分析
      # https://github.com/projectdiscovery/nuclei
      # https://mynixos.com/nixpkgs/package/nuclei
      nuclei

      # https://mynixos.com/nixpkgs/package/nuclei-templates
      nuclei-templates
      # https://mynixos.com/nixpkgs/package/nucleiparser
      nucleiparser

      # 自动化 SQL 注入工具
      # https://github.com/sqlmapproject/sqlmap
      # https://mynixos.com/nixpkgs/package/sqlmap
      sqlmap

      # wifi攻击
      # https://github.com/aircrack-ng/aircrack-ng
      # https://mynixos.com/nixpkgs/package/aircrack-ng
      aircrack-ng

      # 社会工程
      # https://github.com/gophish/gophish
      # https://mynixos.com/nixpkgs/package/gophish
      gophish

      # 拿信-windows
      # https://github.com/gentilkiwi/mimikatz
      # https://mynixos.com/nixpkgs/package/mimikatz
      mimikatz
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 入侵检测
      # https://github.com/snort3/snort3
      # https://mynixos.com/nixpkgs/package/snort
      snort
    ];
}
