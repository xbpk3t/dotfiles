{ pkgs, ... }:
{
  # https://x.com/vikingmute/status/2004471362841403485  speed up rust build on macos. Add APP in "Developer Tools".
  home.packages = with pkgs; [
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
  ];
}
