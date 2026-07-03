{
  pkgs,
  ...
}:
{
  # Diagram tools moved to home/base/devops/diagram.nix
  home.packages = with pkgs; [
    mermaid-cli
    plantuml
    pikchr

    d2
  ];
}
