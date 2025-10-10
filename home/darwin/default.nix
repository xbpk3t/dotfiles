{
  myvars,
  lib,
  mylib,
  ...
}: {
  imports = [../base] ++ mylib.scanPaths ./.;

  # FIXME [2025-10-08] 查一下为啥有这么多 stateVersion，能否只定义一次？
  home = {
    username = myvars.username;
    homeDirectory = "/Users/${myvars.username}";
    stateVersion = lib.mkDefault "24.11";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
