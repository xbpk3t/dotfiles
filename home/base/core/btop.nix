{
  pkgs,
  config,
  ...
}: {
  # https://github.com/aristocratos/btop
  # 【技术选型】简单说明，为啥同时使用 btop 和 htp? 以及为什么不需要 glances
  ##  glances 本质是个services (还是个WebAPP)。但是其核心是“轻量级monitor系统”，glances还分可以分为server模式和client模式，所有slave机器都需要安装glances的server，master开启client模式就可以收集所有slave的数据（类似prometheus这样的pull模式）。所以也可以理解为局域网下的prom（glances不适合在公网做monitor），感觉意思不大。
  ## htop：更像 Better top，核心是 process + CPU/内存 的交互与操作
  ## btop：更像 轻量系统仪表盘，把 procs/mem/Disk/net/CPU 放到一屏里。btop的procs里没有 nice、priority、virt/res/shr 这类字段。所以仍然需要htop

  programs.btop = {
    enable = true;
    package = pkgs.btop.override {
      # 注意 rocm 只支持 x86_64-linux
      rocmSupport = pkgs.stdenv.isLinux;
      cudaSupport = true;
    };
    settings = {
      vim_keys = true;
      rounded_corners = true;
      proc_tree = true;
      show_gpu_info = "on";
      show_uptime = true;
      show_coretemp = true;
      cpu_sensor = "auto";
      show_disks = true;
      only_physical = true;
      io_mode = true;
      io_graph_combined = false;
    };
  };

  # https://mynixos.com/home-manager/options/programs.htop
  programs.htop = {
    enable = true;
    settings =
      {
        color_scheme = 6;
        cpu_count_from_one = 0;
        delay = 15;
        fields = with config.lib.htop.fields; [
          PID
          USER
          PRIORITY
          NICE
          M_SIZE
          M_RESIDENT
          M_SHARE
          STATE
          PERCENT_CPU
          PERCENT_MEM
          TIME
          COMM
        ];
        highlight_base_name = 1;
        highlight_megabytes = 1;
        highlight_threads = 1;
      }
      // (with config.lib.htop;
        leftMeters [
          (bar "AllCPUs2")
          (bar "Memory")
          (bar "Swap")
          (text "Zram")
        ])
      // (with config.lib.htop;
        rightMeters [
          (text "Tasks")
          (text "LoadAverage")
          (text "Uptime")
          (text "Systemd")
        ]);
  };
}
