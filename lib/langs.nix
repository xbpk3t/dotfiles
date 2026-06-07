{
  lspPkgs =
    pkgs: with pkgs; [
      # https://github.com/nix-community/nixd
      nixd
      # https://github.com/oxalica/nil
      nil

      rust-analyzer
      rustfmt

      # [2026-04-26] 跟 gotools 的 modernize pkg conflicts 了
      # (lib.lowPrio gopls)

      zls

      clang-tools

      typescript
      typescript-language-server
      vscode-langservers-extracted
      yaml-language-server
      bash-language-server
      dockerfile-language-server

      terraform-ls
      helm-ls

      # [2026-04-28] 相比更好（lua-lsp已经基本上EOL了，）
      lua-language-server

      texlab

      marksman
      taplo

      pyright
      ruff
    ];
}
