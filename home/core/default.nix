{
  mylib,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [
    # Basic utilities

    # [7 Amazing Terminal API Tools You Need To Try](https://www.youtube.com/watch?v=eyXxEBZMVQI)
    curl
    wget
    # 终端复用
    screen

    # [2026-04-25] darwin 上rebuild失败
    # dateutils # 操作日期和时间表达式 dateadd、datediff、strptime

    # 文件处理
    tree
    file
    which
  ];
}
