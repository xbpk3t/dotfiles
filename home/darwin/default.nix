{
  mylib,
  pkgs,
  lib,
  ...
}: {
  imports = [../base] ++ mylib.scanPaths ./.;

  home.packages = with pkgs; [
    # （用来替代smctemp）
    # powermetrics
    # 在M芯片之后，不再暴露传统的 SMC 温度传感器给 powermetrics，只展示不同level（nominal, fair, serious, critical）
    # https://mynixos.com/nixpkgs/package/macmon
    # https://github.com/vladkens/macmon
    macmon

    launchk
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # 让 hm 生成并管理 ~/Applications/Home Manager Apps 下的 .app，之前需要使用 mac-app-util 这个flake来实现该操作，现在hm本身支持该操作了
  # 注意 linkApps 和 copyApps 是互斥的，而hm通常默认启用 linkApps，且linkApps 有时确无法确保 spotlight确定可以index到相应APP，所以这里显式关闭 linkApps，只保留 copyApps
  # https://mynixos.com/options/targets.darwin.linkApps
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;

  # lfz: 模糊搜索已加载的 launchd services。
  #
  # 定位：
  #   这不是一个 launchd 管理器，而只是一个轻量级的 service target 选择器。
  #   它的作用是快速找到 launchd service target，例如：
  #
  #     gui/501/com.example.agent
  #     system/com.example.daemon
  #

  #
  # 搜索范围：
  #   1. `launchctl list`
  #      列出当前用户上下文中已加载的 launchd jobs。
  #      函数会把每个 label 转换成：
  #
  #        gui/$(id -u)/<label>
  #
  #   2. `sudo launchctl list`
  #      列出 system domain 下已加载的 launchd jobs。
  #      函数会把每个 label 转换成：
  #
  #        system/<label>
  #
  # 为什么使用 fzf：
  #   fzf 可以对所有已加载的 launchd service target 做快速模糊搜索。
  #   搜索结果中的每一行都已经是可直接传给 launchctl 的 service target。
  #
  # 预览行为：
  #   fzf 的 preview 窗口会先执行：
  #
  #     launchctl print <target>
  #
  #   如果失败，再尝试执行：
  #
  #     sudo launchctl print <target>
  #
  #   这样用户态 services 和系统态 services 都可以在 preview 中查看详情。
  #
  # 注意事项：
  #   - 只搜索当前已经加载的 services。
  #   - 不搜索磁盘上尚未加载的 plist 文件。
  #   - 不会修改、重启、启用或禁用任何 service。
  #   - 因为包含 system services，运行 lfz 时可能触发 sudo 密码提示。
  #
  # 用法：
  #   lfz
  #
  # 典型工作流：
  #   target="$(lfz)"
  #   launchctl print "$target"
  #   launchctl kickstart -k "$target"
  programs.zsh.initContent = lib.mkAfter ''
    lfz() {
      {
        launchctl list | awk -v u="$(id -u)" 'NR>1 && $3 {print "gui/" u "/" $3}'
        sudo launchctl list | awk 'NR>1 && $3 {print "system/" $3}'
      } \
        | sort -u \
        | fzf --prompt='launchd > ' \
            --preview='launchctl print {} 2>/dev/null || sudo launchctl print {} 2>/dev/null'
    }
  '';
}
