{pkgs, ...}: {
  home.packages = with pkgs; [
    termscp
    sshpass

    # https://mynixos.com/nixpkgs/package/lazyssh
    # https://github.com/Adembc/lazyssh
    lazyssh
  ];
}
