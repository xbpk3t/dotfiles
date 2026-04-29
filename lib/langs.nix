{
  lspPkgs = pkgs:
    with pkgs; [
      # https://mynixos.com/nixpkgs/package/nixd
      # https://github.com/nix-community/nixd
      nixd
      # https://mynixos.com/nixpkgs/package/nil
      # https://github.com/oxalica/nil
      nil

      # https://mynixos.com/nixpkgs/package/rust-analyzer
      rust-analyzer
      # https://mynixos.com/nixpkgs/package/rustfmt
      rustfmt

      # https://mynixos.com/nixpkgs/package/gopls
      # [2026-04-26] 跟 gotools 的 modernize pkg conflicts 了
      # (lib.lowPrio gopls)

      # https://mynixos.com/nixpkgs/package/zls
      zls

      # https://mynixos.com/nixpkgs/package/clang-tools
      clang-tools

      # https://mynixos.com/nixpkgs/package/typescript
      typescript
      # https://mynixos.com/nixpkgs/package/typescript-language-server
      typescript-language-server
      # https://mynixos.com/nixpkgs/package/vscode-langservers-extracted
      vscode-langservers-extracted
      # https://mynixos.com/nixpkgs/package/yaml-language-server
      yaml-language-server
      # https://mynixos.com/nixpkgs/package/bash-language-server
      bash-language-server
      # https://mynixos.com/nixpkgs/package/dockerfile-language-server
      dockerfile-language-server

      # https://mynixos.com/nixpkgs/package/terraform-ls
      terraform-ls
      # https://mynixos.com/nixpkgs/package/helm-ls
      helm-ls

      # https://mynixos.com/nixpkgs/package/lua-language-server
      # [2026-04-28] 相比更好（lua-lsp已经基本上EOL了，）
      lua-language-server

      # https://mynixos.com/nixpkgs/package/texlab
      texlab

      # https://mynixos.com/nixpkgs/package/marksman
      marksman
      # https://mynixos.com/nixpkgs/package/taplo
      taplo

      # https://mynixos.com/nixpkgs/package/pyright
      pyright
      # https://mynixos.com/nixpkgs/package/ruff
      ruff
    ];
}
