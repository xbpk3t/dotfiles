{pkgs, ...}: {
  # https://github.com/nix-community/nix-direnv
  # https://mynixos.com/home-manager/options/programs.direnv
  # https://mynixos.com/nixpkgs/options/programs.direnv

  # https://blog.therainisme.com/nixos

  home.packages = with pkgs; [
    # why: nixpkgs 当前锁定版本里的 direnv-2.37.1 在 Darwin 上打包有回归：
    # package.nix 里强制 env.CGO_ENABLED = 0，但上游 GNUmakefile 在 Darwin 上又加
    # -linkmode=external，导致构建时报
    # "-linkmode=external requires external (cgo) linking, but cgo is not enabled"。
    # 在上游修复或锁版本回退前，先禁用 direnv / nix-direnv，避免 macos-ws deploy 失败。
    # direnv
    # nix-direnv

    # https://github.com/Mic92/direnv-instant

    devbox # [devbox - MyNixOS](https://mynixos.com/nixpkgs/package/devbox)
  ];

  # why: 见上面的 Darwin 构建回归说明；暂时整块禁用，避免 HM 拉入 pkgs.direnv。
  # programs.direnv = {
  #   enable = true;
  #   silent = false;
  #   #    loadInNixShell = true;
  #
  #   package = pkgs.direnv;
  #   # 启用 nix-direnv 集成以提高性能
  #   nix-direnv = {
  #     enable = true;
  #     package = pkgs.nix-direnv;
  #   };
  #
  #   #    direnvrcExtra = "";
  #
  #   enableZshIntegration = true;
  #
  #   # 自动允许 .envrc 文件（可选，安全考虑建议设为 false）
  #   # stdlib = ''
  #   #   # 自定义 stdlib 配置
  #   # '';
  #
  #   config = {
  #     # 全局配置
  #     global = {
  #       # 禁用提示，避免干扰
  #       warn_timeout = "24h";
  #       # 设置缓存目录
  #       # cache_dir = "$HOME/.cache/direnv";
  #     };
  #   };
  # };
}
