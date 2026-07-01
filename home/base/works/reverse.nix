{
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.isLinux [
      # 分类1：逆向框架 & GUI（Linux-only）
      # iaito
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 分类2：动态调试 & 分析（Linux-only）
      # strace                        # tags(desc): 调试分析 > 系统调用 > 追踪
      # ltrace（strace 已覆盖调用追踪，使用频率低）
      # ltrace                        # tags(desc): 调试分析 > 库调用 > 追踪
      # valgrind                      # tags(desc): 调试分析 > 内存 > 泄漏检测
      # rr（反向调试场景极少，需要时再启）
      # rr                            # tags(desc): 调试分析 > 反向调试 > 录放
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 分类3：二进制文件分析（Linux-only）
      # pev
      # pe-bear
      # detect-it-easy
    ];
}
