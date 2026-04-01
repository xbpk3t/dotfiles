{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.modules.AI.skills;
  remoteCatalog = import ./skills-catalog.nix;
  remoteSources =
    lib.mapAttrs (_: repo: {
      inherit (repo) input subdir;
    })
    remoteCatalog;
  remoteEnabledSkills = lib.flatten (lib.mapAttrsToList (_: repo: repo.skills) remoteCatalog);
in {
  imports = [
    inputs.agent-skills.homeManagerModules.default
  ];

  options.modules.AI.skills = with lib; {
    enable = mkEnableOption "Enable agent skills for Codex";
  };

  config = lib.mkIf cfg.enable {
    # https://github.com/ymat19/dotfiles/blob/main/modules/ai-agent.nix
    # https://github.com/edmundmiller/dotfiles/blob/main/skills/flake.nix
    # https://github.com/ryoppippi/dotfiles/blob/main/nix/modules/home/agent-skills.nix
    # https://github.com/mikinovation/dotfiles/blob/main/config/nix/configs/agent-skills.nix
    # https://github.com/mikinovation/dotfiles/blob/main/config/nix/flake.nix
    # https://github.com/i9wa4/dotfiles/blob/main/nix/home-manager/modules/agent-skills.nix
    programs.agent-skills = {
      enable = true;
      sources =
        {
          local = {
            path = ./skills;
          };
        }
        // remoteSources;

      skills = {
        # 注意这里没有 enableAll = true，因为如果整仓开启会让配置失去控制力，不利于指定需要的skills
        enableAll = ["local"];
        enable = remoteEnabledSkills;
      };

      # 注意这个 targets 是用来把 skills folder 放到不同cli工具的folder，以实现skills的复用。所以所有这里配置了的 targets 里的 skills 都是完全一致的。
      targets.codex = {
        enable = true;
        # dest = ".agents/skills";
        dest = ".codex/skills";
        # 技术要点：copy-tree 避免 symlink 在部分工具/环境中失效
        #        structure = "copy-tree";
        # structure = "link";
        # structure = "symlink-tree";
        # link: home.file symlinks
        # symlink-tree and copy-tree run in home.activation.
        # symlink-tree: rsync -a --delete (preserve symlinks)
        # copy-tree: rsync -aL --delete (dereference symlinks).
        # [2026-03-07] 遇到了个问题，默认link，codex无法读取skills，所以改为 copy-tree
        # structure = "copy-tree";
        structure = "link";
      };
    };
  };
}
