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
    packages = with pkgs; [
      alacritty
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
