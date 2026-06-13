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
      # https://github.com/resurrecting-open-source-projects/safecopy
      # safecopy                      # tags(desc): 磁盘镜像 > 坏道 > 安全复制
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 分类2：文件雕刻 & 恢复（Linux-only）
      # extundelete                   # tags(desc): 数据恢复 > Ext3/4 > 文件恢复
      # https://github.com/nickhall/recoverjpeg
      # recoverjpeg（foremost 已覆盖 JPEG 文件雕刻恢复）
      # recoverjpeg                   # tags(desc): 数据恢复 > JPEG > 图片恢复
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 分类3：文件 & 元数据解析（Linux-only）
      # https://github.com/mentebinaria/pev
      # pev                           # tags(desc): 文件分析 > PE > 格式验证
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # 分类4：内存 & 系统取证（Linux-only）
      # usbrip                        # tags(desc): 系统取证 > USB > 连接记录
    ];
}
