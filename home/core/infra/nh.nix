{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.infra.nh;
in
{
  options.modules.infra.nh.enable = lib.mkEnableOption "Nix helper tools (nh, nvd, comma)";

  config = lib.mkIf cfg.enable {
    # Additional Nix management tools
    home.packages = with pkgs; [
      # nom
      nix-output-monitor
      # https://mynixos.com/nixpkgs/package/nvd
      nvd
    ];

    # 把这些支持 HM 的 Nix 相关工具放在这里，以便 Darwin 和 NixOS 复用。
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
        # [2026-05-01] 实际用了一下，两点说明：
        # ## 1、简单来说 comma = 临时运行一个命令。而 nix-shell -p pkg 则用来进入已安装该nixpkg的shell。二者都不会污染宿主机本身的shell。我通常用后者，那你觉得前者有什么真正独一无二的场景吗？comma 真正有价值的场景是“命令名已知，包名未知”
        # ## 2、comma 不适合替代你已经安装好的命令。比如说 `, nuclei`很有可能会再次去安装这个pkg
        comma = {
          # what: 让 `comma` 也复用 nix-index-database 提供的 wrapper。
          # why: 既然当前已经引入预生成 database，就顺手把 ad-hoc command lookup 统一到同一条索引链路，
          #      避免后面排查 `nix-locate` 和 `comma` 行为时出现两套数据来源。
          enable = true;
        };
      };
    };
  };
}
