{
  myvars,
  mylib,
  pkgs,
  ...
}: {
  imports = [../base] ++ mylib.scanPaths ./.;

  home = {
    username = myvars.username;
    homeDirectory = "/Users/${myvars.username}";
    # mac-app-util 配置项
    # TODO 这里能否做一个配置化启用的连动？
    packages = with pkgs; [
      alacritty
      # zed
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
