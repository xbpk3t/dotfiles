{pkgs, ...}: {
  # https://github.com/nix-community/nix-direnv
  # https://mynixos.com/home-manager/options/programs.direnv
  # https://mynixos.com/nixpkgs/options/programs.direnv

  # https://blog.therainisme.com/nixos

  home.packages = with pkgs; [
    direnv
    nix-direnv

    devbox # [devbox - MyNixOS](https://mynixos.com/nixpkgs/package/devbox)
  ];

  programs.direnv = {
    enable = true;
    silent = false;
    #    loadInNixShell = true;

    package = pkgs.direnv;
    # 启用 nix-direnv 集成以提高性能
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv;
    };

    #    direnvrcExtra = "";

    enableZshIntegration = true;

    # 自动允许 .envrc 文件（可选，安全考虑建议设为 false）
    # stdlib = ''
    #   # 自定义 stdlib 配置
    # '';

    config = {
      # 全局配置
      global = {
        # 禁用提示，避免干扰
        warn_timeout = "24h";
        # 设置缓存目录
        # cache_dir = "$HOME/.cache/direnv";
      };
    };
  };
}
