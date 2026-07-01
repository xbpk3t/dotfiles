{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./cc-connect.nix
    ./mcp.nix
    ./codex.nix
    ./claude.nix
    ./pi-agent.nix
    ./skills.nix
  ];
  home.packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    apm
  ];
}
