{pkgs, ...}: {
  home.packages = with pkgs; [
    # 系统调用跟踪
    strace

    # 库调用跟踪
    ltrace

    # 查看进程打开的文件
    lsof

    # 系统性能监控工具集
    sysstat

    # 磁盘与进程 I/O 监控
    iotop-c

    # 网络流量监控
    iftop

    # 全面系统性能监视（CPU/内存/磁盘/网络）
    nmon

    # 压测与基准测试
    sysbench

    # 杀进程、进程树等常用进程工具合集
    psmisc

    # 进程信息查看（比 ps 更友好）
    procs

    # 实用工具集（ts 等小工具）
    moreutils
  ];
}
