{pkgs, ...}: {
  home.packages = with pkgs; [
    # https://github.com/nix-community/noogle
    # https://noogle.dev/
    # nix search nixpkgs noogle
    # what: nixpkgs 里的 Noogle 终端搜索前端，用来查 Nix API / lib / builtins 函数。
    # why: 这类检索需求属于开发型主机共享能力，适合放在 langs 层，而不是 mac 专属或 core 基础层。
    noogle-search

    ###### nixpkgs 打包相关 ##########
    # https://mynixos.com/nixpkgs/package/nurl
    nurl
  ];

  # https://mynixos.com/home-manager/options/programs.nix-init
  # https://mynixos.com/nixpkgs/package/nix-init
  # nix-init 是基于nurl实现的
  # nix-init 和 nurl 都可以用来给“没有nixpkgs”的pkg手动打包。但是
  programs.nix-init = {
    enable = true;
  };

  programs.zsh.shellAliases = {
    # noogle-search 是 nixpkgs 中的实际可执行文件名；补一个更直观的入口。
    noogle = "noogle-search";
  };
}
