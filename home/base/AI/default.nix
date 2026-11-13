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
    ./dsh.nix
    ./skills.nix
    ./opencli-browser.nix
  ];
  home.packages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
    apm
  ];

}
