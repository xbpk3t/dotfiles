{pkgs, ...}: {
  home.packages = with pkgs; [
    nmap
    katana

    subfinder # https://github.com/projectdiscovery/subfinder 【子域名发现工具，支持多个数据源和被动枚举】它已成为sublist3r项目的继承者。SubFinder使用被动源，搜索引擎，Pastebins，Internet Archives等来查找子域，然后使用灵感来自于altdns的置换模块来生成排列，并使用强大的bruteforcing引擎快速的解析它们。如果需要，它也可以执行纯粹的爆破。此外，SubFinder还具有高可定制性。其代码构建模块化的特点，使你能够轻松地添加功能或移除错误。
    naabu # https://github.com/projectdiscovery/naabu 端口扫描工具

    # https://github.com/openwall/john/
    # https://mynixos.com/nixpkgs/package/john
    # used to crack passwords
    john
  ];
}
