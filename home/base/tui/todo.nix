{pkgs, ...}: {
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/dooit
    # https://github.com/dooit-org/dooit
    # dooit
    todui

    # https://mynixos.com/nixpkgs/package/dooit-extras
    # https://github.com/dooit-org/dooit-extras
  ];
}
