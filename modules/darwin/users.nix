# Darwin user configuration
# Contains user configuration that can be shared between multiple hosts
{
  myvars,
  lib,
  pkgs,
  ...
}: {
  # Default user configuration (can be overridden by host-specific settings)
  users.users = {
    # Main user configuration with defaults
    "${myvars.username}" = {
      home = "/Users/${myvars.username}";
      description = myvars.username;
      shell = lib.mkDefault (pkgs.zsh + "/bin/zsh");
      openssh.authorizedKeys.keys = myvars.SSHPubKeys;
    };

    # Note: Additional users should be created manually on macOS or via host-specific configuration
  };

  # Default Nix settings (can be overridden by host-specific settings)
  # 注意：nix.enable = false 时，nix-darwin 不会管理 Nix 安装，以下设置不会写入 nix.conf
  nix.settings = {
    trusted-users = lib.mkDefault [myvars.username];
    # 允许信任 flake.nix 的 nixConfig（如 extra-substituters / extra-trusted-public-keys）
    accept-flake-config = true;
  };

  # Determinate Nix 需要通过 /etc/nix/nix.custom.conf 注入自定义配置
  # 这里仅启用 accept-flake-config + trusted-users，不重复 cache 列表
  environment.etc."nix/nix.custom.conf".text = ''
    # 允许信任 flake.nix 的 nixConfig（如 extra-substituters / extra-trusted-public-keys）
    accept-flake-config = true

    # 允许当前用户读取受限配置并使用额外缓存
    trusted-users = root ${myvars.username}

    # Numtide cache（llm-agents / codex）
    extra-substituters = https://cache.numtide.com
    extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=

    # 系统级 substituters（确保 deploy-rs / nix run 也能命中）
    substituters = https://cache.nixos.org https://cache.garnix.io https://nix-community.cachix.org https://watersucks.cachix.org https://cache.numtide.com

    # 对应 substituters 的公钥（缺 key 的 cache 不要放进来）
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= watersucks.cachix.org-1:6gadPC5R8iLWQ3EUtfu3GFrVY7X6I4Fwz/ihW25Jbv8= niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=

    # 允许非 trusted user 也能使用的 substituters（防止 “untrusted substituter” 报警）
    trusted-substituters = https://cache.nixos.org https://cache.garnix.io https://nix-community.cachix.org https://watersucks.cachix.org https://cache.numtide.com
  '';

  # Shell configuration - make shells available system-wide
  environment.shells = lib.mkDefault [
    (pkgs.zsh + "/bin/zsh")
    (pkgs.bash + "/bin/bash")
  ];

  environment.pathsToLink = lib.mkDefault [
    # "/share/zsh"
    # "/share/bash-completion"
    # "/share/nvim"
    # "/share/man"
  ];
}
