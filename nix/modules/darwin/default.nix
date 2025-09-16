# Darwin-specific modules
{pkgs, ...}: {
  imports = [
    ./directories.nix
    ./brew.nix
    ./host-users.nix
    ./launchd.nix
    ./stylix.nix
    ./system.nix
    ./system-limits.nix
    ./users.nix
  ];

  # Enable nix-darwin's management of the Nix installation for Determinate compatibility
  nix.enable = true;
  nix.settings.experimental-features = ["nix-command" "flakes"]; # Add 'flakes' if you're using flakes

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Allow broken packages
  nixpkgs.config.allowBroken = true;

  # 声明式地保护关键包不被 GC 清理
  # 通过将关键包添加到系统包中，确保它们被系统 profile 引用
  environment.systemPackages = with pkgs; [
    # 保护 nix 本身
    nix

    # 保护 home-manager
    home-manager

    # 字体包 - 确保在系统级别可用
    nerd-fonts.jetbrains-mono
    noto-fonts-color-emoji
  ];

  # Note: Nix settings, garbage collection, and optimization are managed by Determinate Nix
  # For manual garbage collection, use: nix-collect-garbage --delete-older-than 7d
  # 关键包保护通过 environment.systemPackages 声明式配置
}
