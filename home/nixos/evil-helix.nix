{pkgs, ...}: let
  enableEvilHelix = true; # Set to true to enable the configuration
in {
  home = {
    packages = with pkgs; (
      if enableEvilHelix
      then [
        evil-helix
        cmake-language-server
        jsonnet-language-server
        luaformatter
        lua-language-server
        marksman
        taplo
        nil
        jq-lsp
        vscode-langservers-extracted
        bash-language-server
        awk-language-server
        vscode-extensions.llvm-vs-code-extensions.vscode-clangd
        clang-tools
        docker-compose-language-service
        docker-compose
        docker-language-server
        typescript-language-server
      ]
      else []
    );

    file.".config/helix/languages.toml".text =
      if enableEvilHelix
      then ''
        [language-server.nil]
        command = "nil"

        [language-server.lua]
        command = "lua-language-server"

        [language-server.json]
        command = "vscode-json-languageserver"

        [language-server.markdown]
        command = "marksman"
      ''
      else "";

    file.".config/helix/config.toml".text =
      if enableEvilHelix
      then ''
        theme = "catppuccin_mocha"
        #theme = "ao"

        [editor]
        evil = true
        end-of-line-diagnostics = "hint"
        auto-pairs = true
        mouse = true
        middle-click-paste = true
        shell = ["zsh", "-c"]
        line-number = "absolute"
        auto-completion = true
        path-completion = true
        auto-info = true
        color-modes = true
        popup-border = "all"
        clipboard-provider = "wayland"
        indent-heuristic = "hybrid"

        [editor.statusline]
        left = ["mode", "spinner"]
        center = ["file-absolute-path", "total-line-numbers", "read-only-indicator", "file-modification-indicator"]
        right = ["diagnostics", "selections", "position", "file-encoding", "file-line-ending", "file-type"]
        separator = "│"
        mode.normal = "NORMAL"
        mode.insert = "INSERT"
        mode.select = "SELECT"

        [editor.lsp]
        enable = true
        display-messages = true
        display-progress-messages = true

        [editor.inline-diagnostics]
        cursor-line = "hint"
        other-lines = "hint"
      ''
      else "";
  };
}
