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
}
