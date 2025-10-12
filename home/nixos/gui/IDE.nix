{pkgs, ...}: {
  home.packages = with pkgs; [
    jetbrains.goland # https://mynixos.com/nixpkgs/package/jetbrains.goland
  ];
}
