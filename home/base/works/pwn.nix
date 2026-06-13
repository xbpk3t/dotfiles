{
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      # === Red Team / 红队 ===

      # 渗透测试框架
      # https://github.com/rapid7/metasploit-framework
      metasploit

      # 社会工程
      # https://github.com/gophish/gophish
      gophish

      # 拿信-windows
      # https://github.com/gentilkiwi/mimikatz
      mimikatz

      python313Packages.impacket
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 分类1：AD Internal Pentest（Linux-only）
      # bloodhound # tags(desc): 信息收集 > AD域 > 可视化分析

      # 分类1：Hash 破解（Linux-only）
      # johnny # tags(desc): 密码破解 > GUI > John前端

      # 分类2：在线爆破（Linux-only）
      # crowbar # tags(desc): 暴力破解 > 在线服务 > RDP/SSH

      # 分类4：专项破解（Linux-only）
      # veracrypt # tags(desc): 专项破解 > VeraCrypt > 卷密码
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 分类2：隧道 & 后渗透（Linux-only）
      # ligolo-ng # tags(desc): 隧道代理 > 网络层 > 反向代理
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # === Blue / 蓝队防御 ===

      # 入侵检测
      # https://github.com/snort3/snort3
      snort
    ];
}
