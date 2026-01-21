{
  lspPkgs = pkgs:
    with pkgs; [
      # https://mynixos.com/nixpkgs/package/nixd
      nixd
      # https://mynixos.com/nixpkgs/package/nil
      nil

      # https://mynixos.com/nixpkgs/package/rust-analyzer
      rust-analyzer
      # https://mynixos.com/nixpkgs/package/rustfmt
      rustfmt

      # https://mynixos.com/nixpkgs/package/gopls
      gopls
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
