{
  config,
  lib,
  pkgs,
  ...
}:
let
  lspPkgs = with pkgs; [
    # Nix
    nixd
    nil

    # Rust
    rust-analyzer
    rustfmt

    # Zig
    zls

    # C/C++
    clang-tools

    # TypeScript/JavaScript
    typescript
    typescript-language-server

    # YAML
    yaml-language-server

    # Bash
    bash-language-server

    # Docker
    dockerfile-language-server

    # Terraform
    terraform-ls

    # Helm
    helm-ls

    # Lua
    lua-language-server

    # TeX
    texlab

    # Markdown
    marksman

    # TOML
    taplo

    # Python
    pyright
    ruff

    # API
    api-linter

    # General
    cookiecutter
    dotenv-linter
  ];

  cfg = config.modules.langs.lsp;
in
{
  options.modules.langs.lsp = with lib; {
    enable = mkEnableOption "Enable common LSP/toolchain packages";

    packages = mkOption {
      type = types.listOf types.package;
      default = lspPkgs;
      description = "Common LSP/toolchain packages shared by IDEs.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = cfg.packages;
  };
}
