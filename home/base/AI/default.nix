{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./mcp.nix
    ./codex.nix
    ./claude.nix
    ./dagu.nix
    ./pi-agent.nix
    ./skills.nix
  ];
  home.packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    apm
  ];



  
}
