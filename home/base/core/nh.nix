{
  globals,
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
      # https://github.com/nix-community/comma
      # comma 的核心价值是临时运行一次性工具，不必正式装入环境。
      # 是啥：临时运行 nixpkgs 工具的快捷方式：在命令前加 “,”，就能不安装也运行（通常基于 nix shell + 索引查询工作流）。
      # 有啥用：偶尔用一下 rg/jq/shellcheck 等工具，不污染全局环境、不改项目依赖。
      # 怎么用：安装 comma 后直接 `,rg foo` / `,jq ...`；首次运行会拉取/缓存对应包。
      # 决策：用在你“经常临时用工具但不想装”的场景；如果你没有 Nix 或更喜欢用容器跑一次性工具，可不必。
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
      flake = globals.workspace.projectRoot;
    };
  };

  home.sessionVariables = let
    projectPath = globals.workspace.projectRoot;
  in {
    FLAKE = projectPath;
    NIXOS_CONFIG = projectPath;
  };
}
