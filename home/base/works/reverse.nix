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
      # https://github.com/radareorg/iaito
      # iaito                         # tags(desc): 逆向框架 > GUI > Radare2前端
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
      # https://github.com/mentebinaria/pev
      # pev                           # tags(desc): 文件分析 > PE > 结构查看
      # https://github.com/hasherezade/pe-bear
      # pe-bear                       # tags(desc): 文件分析 > PE > GUI查看器
      # https://github.com/horsicq/Detect-It-Easy
      # detect-it-easy                # tags(desc): 文件分析 > 格式识别 > 查壳类型
    ];
}
