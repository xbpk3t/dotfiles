{
  myvars,
  pkgs,
  ...
}: {
  # Additional Nix management tools
  home.packages = with pkgs; [
    # nom
    nix-output-monitor
    # https://mynixos.com/nixpkgs/package/nvd
    nvd
  ];

  # !!! 把这些支持hm的“nix相关工具”，挪到hm里。以便在darwin和nixos之间复用。
  # sudo nix run nix-darwin -- switch --flake ".#macos-ws"
  # nh darwin switch . -H macos-ws
  programs = {
    # https://mynixos.com/home-manager/options/programs.nix-index
    nix-index = {
      enable = true;
    };

    nix-index-database = {
      comma = {
        # what: 让 `comma` 也复用 nix-index-database 提供的 wrapper。
        # why: 既然当前已经引入预生成 database，就顺手把 ad-hoc command lookup 统一到同一条索引链路，
        #      避免后面排查 `nix-locate` 和 `comma` 行为时出现两套数据来源。
        enable = true;
      };
    };

    # Nix Helper (nh) configuration
    # https://github.com/viperML/nh
    # https://mynixos.com/home-manager/options/programs.nh
    # Ensure nix tooling resolves the flake inside OCI containers instead of relying on host paths.
    #
    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 5";
      };
      flake = myvars.projectRoot;
    };
  };

  home.sessionVariables = let
    projectPath = myvars.projectRoot;
  in {
    FLAKE = projectPath;
    NIXOS_CONFIG = projectPath;
  };
}
