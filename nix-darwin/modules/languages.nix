{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Go 语言
    # go - 由 home-manager 管理
    gofumpt
    golangci-lint
    goreleaser
    protoc-gen-go
    protoc-gen-go-grpc
    gopls
    golines
    goimports-reviser

    # Node.js 生态
    nodejs
    nodePackages.eslint
    nodePackages.pnpm
    yarn
    # wrangler  # 构建时间太长，暂时移除

    # Python
    uv

    # Rust
    rustup

    # 其他语言工具
    gcc
    clang-tools
    nasm
    automake
    cmake
    binutils
    gobject-introspection
    gnumake

    # Web 开发
    tailwindcss
    tailwindcss-language-server

    # php

    # Elixir
    # elixir

    # Android 开发
    # android-tools
  ];
}
