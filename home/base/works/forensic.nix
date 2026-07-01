{
  lib,
  pkgs,
  ...
}:
{
  home.packages =
    with pkgs;
    lib.optionals pkgs.stdenv.isLinux [
      # 分类1：磁盘镜像 & 恢复（Linux-only）
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 分类2：文件雕刻 & 恢复（Linux-only）
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 分类3：文件 & 元数据解析（Linux-only）
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 分类4：内存 & 系统取证（Linux-only）
    ];
}
