{
  mylib,
  pkgs,
  ...
}: {
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/todoist
    # https://github.com/sachaos/todoist

    # https://github.com/larksuite/cli
    # https://x.com/xiaohu/status/2037533774175772773
  ];
}
