{pkgs, ...}: {
  home.packages = with pkgs; [
    sshpass

    # https://mynixos.com/nixpkgs/package/lazyssh
    # https://github.com/Adembc/lazyssh
    # 用 lazyssh 替代了 sshs
    lazyssh

    # 文件传输工具
    # https://mynixos.com/nixpkgs/package/trzsz-ssh
    # [2026-04-16] 移除 termscp，两点原因：1、我的核心需求是临时上传、下载文件。基于此需求 trzsz 要比 termscp 更好用。2、termscp安装时需要build，并且很慢。
    # trzsz 具体用法：
    ## 1、用 tssh --install-trzsz user@your-vps 在目标VPS上安装 trzsz （默认装到 ~/.local/bin/，在NixOS下没有相应的更nix的方案，所以暂时这么处理也可）
    ## 2、直接用ssh登录（推荐用tssh登录，兼容性更好，但是ssh也没啥问题）。trz 上传， tsz 下载。
    # [2026-04-20] 给 trzsz-go 打了nixpkgs，之后就不再需要 上面的 install-trzsz 操作了。trzsz的核心在于，服务器装 trzsz-go，本地装 tssh，所以我们这么处理后，就完全OOTB了
    trzsz-ssh
  ];
}
