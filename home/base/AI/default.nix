{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.AI.basePackages;
in
{
  options.modules.AI.basePackages.enable = lib.mkEnableOption "apm (llm-agents)";

  imports = [
    ./mcp.nix
    ./codex.nix
    ./claude.nix
    ./cloudcli.nix
    ./dagu.nix
    ./dsh.nix
    ./opencode.nix
    ./skills.nix
  ];
  config.home.packages = lib.optionals cfg.enable (
    with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
    [
      apm
    ]
  );

}
