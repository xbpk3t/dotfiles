{
  config,
  lib,
  pkgs,
  ...
}:
let
  lspPkgs = with pkgs; [
    # Go
    gopls

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

    # Lua
    lua-language-server

    # TeX
    texlab

    markdown-oxide

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
    # list option 的 default 会被任何 definition 顶掉；把默认列表也作为
    # definition 参与合并，nix-tools/tf/helm 等模块追加的 LSP 才不会
    # 悄悄替换掉整个默认集合。
    modules.langs.lsp.packages = lib.mkBefore lspPkgs;

    home.packages = cfg.packages;
  };
}
