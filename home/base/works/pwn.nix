{
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      # 信息收集
      # https://github.com/nmap/nmap
      nmap
      # https://github.com/royhills/arp-scan/wiki/arp-scan-User-Guide
      # sudo arp-scan --interface=en0 --localnet
      # [2026-01-21] 用了一下，感觉跟nmap没啥区别，移除掉了
      # arp-scan

      # https://github.com/projectdiscovery/naabu
      # 端口扫描工具
      naabu

      # 渗透测试框架
      # https://github.com/rapid7/metasploit-framework
      metasploit

      # 嗅探欺骗
      # https://github.com/Ettercap/ettercap
      ettercap

      # 内网扫描工具
      # https://github.com/shadow1ng/fscan
      fscan

      # https://github.com/projectdiscovery/subfinder
      # https://github.com/projectdiscovery/subfinder
      # 【子域名发现工具，支持多个数据源和被动枚举】它已成为sublist3r项目的继承者。SubFinder使用被动源，搜索引擎，Pastebins，Internet Archives等来查找子域，然后使用灵感来自于altdns的置换模块来生成排列，并使用强大的bruteforcing引擎快速的解析它们。如果需要，它也可以执行纯粹的爆破。此外，SubFinder还具有高可定制性。其代码构建模块化的特点，使你能够轻松地添加功能或移除错误。
      subfinder

      # https://github.com/projectdiscovery/httpx
      httpx

      # 渗透测试
      # https://github.com/projectdiscovery/katana
      katana

      # 漏洞分析
      # https://github.com/projectdiscovery/nuclei
      nuclei

      nuclei-templates
      nucleiparser

      # 自动化 SQL 注入工具
      # https://github.com/sqlmapproject/sqlmap
      sqlmap

      # wifi攻击
      # https://github.com/aircrack-ng/aircrack-ng
      aircrack-ng

      # 社会工程
      # https://github.com/gophish/gophish
      gophish

      # 拿信-windows
      # https://github.com/gentilkiwi/mimikatz
      mimikatz
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 入侵检测
      # https://github.com/snort3/snort3
      snort
    ];
}
