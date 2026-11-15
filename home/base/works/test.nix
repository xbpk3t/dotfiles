{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.works.test;
in
{
  options.modules.works.test.enable = lib.mkEnableOption "load-test tools (k6 / vegeta / playwright)";

  config.home.packages = lib.optionals cfg.enable (
    with pkgs;
    [
      k6

      vegeta
      # speedtest-cli

      # hyperfine

      playwright
    ]
  );
}
