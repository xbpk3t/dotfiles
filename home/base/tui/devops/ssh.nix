{pkgs, ...}: {
  home.packages = with pkgs; [
    sshpass

    # https://mynixos.com/nixpkgs/package/lazyssh
    # https://github.com/Adembc/lazyssh
    # 用 lazyssh 替代了 sshs
    lazyssh

    # MAYBE [2025-12-23] 做一下termscp预配置。不过还是等一下hm，
    termscp

    # https://mynixos.com/nixpkgs/package/trzsz-ssh
    trzsz-ssh
  ];
}
