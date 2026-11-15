{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.langs.rust;
in
{
  options.modules.langs.rust.enable = lib.mkEnableOption "Rust toolchain";

  # https://x.com/vikingmute/status/2004471362841403485  speed up rust build on macos. Add APP in "Developer Tools".
  config.home.packages = lib.optionals cfg.enable (
    with pkgs;
    [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
    ]
  );
}
