{pkgs, ...}: {
  home.packages = with pkgs; [
    sshpass

    # https://mynixos.com/nixpkgs/package/lazyssh
    # https://github.com/Adembc/lazyssh
    # 用 lazyssh 替代了 sshs
    lazyssh

    # MAYBE: [2025-12-23] 做一下termscp预配置。不过还是等一下hm，
    # termscp每次都要自己build，就很麻烦，所以先注释掉
    # termscp

    # https://mynixos.com/nixpkgs/package/trzsz-ssh
    trzsz-ssh
  ];
}
