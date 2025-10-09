{pkgs, ...}: {
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
}
