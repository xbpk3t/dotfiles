{ pkgs, ... }:

{
  # Disable nix-darwin's management of the Nix installation for Determinate compatibility
  nix.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # 声明式地保护关键包不被 GC 清理
  # 通过将关键包添加到系统包中，确保它们被系统 profile 引用
  environment.systemPackages = with pkgs; [
    # 保护 nix 本身
    nix

    # 保护 home-manager
    home-manager

    # 保护开发工具
    alejandra  # nix formatter
  ];

  # Note: Nix settings, garbage collection, and optimization are managed by Determinate Nix
  # For manual garbage collection, use: nix-collect-garbage --delete-older-than 7d
  # 关键包保护通过 environment.systemPackages 声明式配置
}
