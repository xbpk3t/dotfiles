{pkgs, ...}: {
  home.packages = with pkgs; [
    #    zed-editor
    #    code-cursor
    jetbrains.goland # https://mynixos.com/nixpkgs/package/jetbrains.goland
  ];
}
