{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.modules.AI.skills;
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
      sources = {
        local = {
          path = ./skills;
        };
      };
      skills = {
        # enableAll = [ "local" ];
        enableAll = true;
      };

      targets.codex = {
        enable = true;
        # dest = ".agents/skills";
        dest = ".codex/skills";
        # link: home.file symlinks
        # symlink-tree and copy-tree run in home.activation.
        # symlink-tree: rsync -a --delete (preserve symlinks)
        # copy-tree: rsync -aL --delete (dereference symlinks).
        # [2026-03-07] 遇到了个问题，默认link，codex无法读取skills，所以改为 copy-tree
        # structure = "copy-tree";
        structure = "link";
      };
    };

    # [2026-03-08] 直接用taskfile管理第三方skills了，所以注释掉
    #  home.file.".agents/.skill-lock.json" = {
    #    source =
    #      config.lib.file.mkOutOfStoreSymlink
    #      "${config.home.homeDirectory}/Desktop/dotfiles/home/base/tui/AI/.skill-lock.json";
    #
    #    force = true;
    #  };
  };
}
