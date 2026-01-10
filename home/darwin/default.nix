{
  myvars,
  mylib,
  ...
}: {
  imports = [../base] ++ mylib.scanPaths ./.;

  home = {
    username = myvars.username;
    homeDirectory = "/Users/${myvars.username}";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # 让 hm 生成并管理 ~/Applications/Home Manager Apps 下的 .app，之前需要使用 mac-app-util 这个flake来实现该操作，现在hm本身支持该操作了
  # 注意 linkApps 和 copyApps 是互斥的，而hm通常默认启用 linkApps，且linkApps 有时确无法确保 spotlight确定可以index到相应APP，所以这里显式关闭 linkApps，只保留 copyApps
  # https://mynixos.com/options/targets.darwin.linkApps
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;
}
