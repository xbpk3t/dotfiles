{pkgs, ...}:
# Wrap GoLand so it always launches through XWayland. JetBrains still
# lacks proper IME support on native Wayland, so we strip the Wayland
# variables before delegating to the upstream launcher.
# goland-x11 = pkgs.symlinkJoin {
#   name = "goland-x11";
#   paths = [pkgs.jetbrains.goland];
#   buildInputs = [pkgs.makeWrapper];
#   postBuild = ''
#     wrapProgram $out/bin/goland \
#       --set GDK_BACKEND x11 \
#       --set QT_QPA_PLATFORM xcb \
#       --set SDL_VIDEODRIVER x11 \
#       --set XDG_SESSION_TYPE x11 \
#       --set NIXOS_OZONE_WL 0 \
#       --unset WAYLAND_DISPLAY \
#       --unset MOZ_ENABLE_WAYLAND \
#       --unset ELECTRON_OZONE_PLATFORM_HINT
#   '';
# };
{
  home.packages = with pkgs; [
    jetbrains.goland
  ];

  # https://mynixos.com/home-manager/options/programs.vscode
  # https://mynixos.com/nixpkgs/packages/vscode-extensions
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    # 保证 settings, ext, keybinds 相应配置文件可写
    mutableExtensionsDir = true;
    # mutableSettings = true;
    # mutableKeybindings = true;

    profiles.default = {
      enableUpdateCheck = true;
      enableExtensionUpdateCheck = true;

      extensions = with pkgs.vscode-extensions; [
        tuttieee.emacs-mcx

        # https://mynixos.com/nixpkgs/package/vscode-extensions.ziglang.vscode-zig
        # https://mynixos.com/nixpkgs/package/vscode-extensions.tiehuis.zig
        # used to replace tiehuis.zig
        ziglang.vscode-zig

        rust-lang.rust-analyzer
        kahole.magit
        graphql.vscode-graphql
        catppuccin.catppuccin-vsc
        bbenoist.nix
        jnoortheen.nix-ide
        golang.go
        ms-python.python
        redhat.vscode-yaml
        ms-azuretools.vscode-docker
        ms-vscode.cpptools
        hashicorp.terraform
        tamasfe.even-better-toml
        timonwong.shellcheck
        dbaeumer.vscode-eslint
        esbenp.prettier-vscode
        streetsidesoftware.code-spell-checker
        eamodio.gitlens
        # vscodevim.vim

        ms-vscode.makefile-tools
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit
        ms-vscode-remote.remote-containers
        github.vscode-pull-request-github
        ibm.output-colorizer
        oderwat.indent-rainbow
        formulahendry.code-runner
        gruntfuggly.todo-tree
      ];

      userSettings = {
        "breadcrumbs.enabled" = true;
        "diffEditor.ignoreTrimWhitespace" = false;
        "editor.bracketPairColorization.enabled" = true;
        "editor.codeActionsOnSave" = {
          "source.fixAll" = "explicit";
          "source.organizeImports" = "explicit";
        };
        "editor.cursorSmoothCaretAnimation" = "on";
        #      "editor.fontFamily" = "Sarasa Mono SC";
        "editor.fontLigatures" = true;
        #      "editor.fontSize" = 13;
        "editor.formatOnPaste" = true;
        "editor.formatOnSave" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.inlineSuggest.enabled" = true;
        "editor.linkedEditing" = true;
        "editor.minimap.enabled" = false;
        "editor.renderWhitespace" = "boundary";
        "editor.rulers" = [
          80
          100
          120
        ];
        "editor.smoothScrolling" = true;
        "editor.stickyScroll.enabled" = true;
        "editor.tabSize" = 2;
        "editor.wordWrap" = "bounded";
        "editor.wordWrapColumn" = 120;

        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;

        "extensions.autoCheckUpdates" = false;
        "extensions.autoUpdate" = false;

        "files.eol" = "\n";
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;
        "files.trimTrailingWhitespace" = true;
        "files.watcherExclude" = {
          "**/.direnv/**" = true;
          "**/.jj/**" = true;
          "**/node_modules/**" = true;
          "**/target/**" = true;
        };

        "git.autofetch" = true;
        "git.confirmSync" = false;
        "git.enableSmartCommit" = true;

        "gopls" = {
          "staticcheck" = true;
          "usePlaceholders" = true;
        };

        "nix.enableLanguageServer" = true;
        "nix.formatterPath" = "nixfmt";
        "nix.serverPath" = "nixd";

        "python.analysis.autoImportCompletions" = true;
        "python.formatting.provider" = "black";

        "remote.SSH.useLocalServer" = false;

        "rust-analyzer.cargo.buildScripts.enable" = true;
        "rust-analyzer.check.command" = "clippy";

        "search.exclude" = {
          "**/.direnv/**" = true;
          "**/.git/**" = true;
          "**/node_modules/**" = true;
          "**/target/**" = true;
        };

        "security.workspace.trust.untrustedFiles" = "open";

        "telemetry.telemetryLevel" = "off";
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "terminal.integrated.drawBoldTextInBrightColors" = false;
        #      "terminal.integrated.fontFamily" = "Sarasa Mono SC";
        #      "terminal.integrated.fontSize" = 12;

        "todo-tree.general.tags" = [
          "TODO"
          "FIXME"
          "BUG"
          "NOTE"
        ];
        "todo-tree.tree.showScanModeButton" = false;

        "update.mode" = "none";
        "window.autoDetectColorScheme" = false;
        "window.commandCenter" = false;
        "window.titleBarStyle" = "custom";
        #      "workbench.colorTheme" = "Catppuccin Mocha";
        "workbench.editor.enablePreview" = false;
        "workbench.preferredDarkColorTheme" = "Catppuccin Mocha";
        "workbench.startupEditor" = "none";

        "[go]" = {
          "editor.codeActionsOnSave" = {
            "source.organizeImports" = "explicit";
          };
          "editor.defaultFormatter" = "golang.go";
          "editor.formatOnSaveMode" = "file";
        };
        "[graphql]" = {
          "editor.defaultFormatter" = "graphql.vscode-graphql";
        };
        "[json]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[jsonc]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[markdown]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.wordWrap" = "on";
        };
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
        "[python]" = {
          "editor.defaultFormatter" = "ms-python.python";
        };
        "[rust]" = {
          "editor.defaultFormatter" = "rust-lang.rust-analyzer";
        };
        "[toml]" = {
          "editor.defaultFormatter" = "tamasfe.even-better-toml";
        };
        "[typescript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
        };
        "[yaml]" = {
          "editor.defaultFormatter" = "redhat.vscode-yaml";
        };
      };
    };
  };
}
