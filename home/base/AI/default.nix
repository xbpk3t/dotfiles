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
    ./pi-agent.nix
    ./skills.nix
  ];
  #  imports = mylib.scanPaths ./.;
  home.packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    # https://github.com/microsoft/apm
    apm
  ];
}
