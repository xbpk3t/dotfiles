{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Python
    uv

    # Rust
    rustup

    # 其他语言
    # php
    # elixir
    # android-tools

    lua
  ];
}
