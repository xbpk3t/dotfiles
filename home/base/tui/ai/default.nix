{ pkgs, ... }:
{
  imports = [
    ./codex.nix
    ./claude.nix
    ./opencode.nix
  ];

  home.packages = with pkgs; [
    # claude-code-router

    # [2025-11-13] No longer use qwen
    # qwen-code

    # https://github.com/github/spec-kit
    # spec-kit

    # ruler

    # https://mynixos.com/nixpkgs/package/github-mcp-server
    # github-mcp-server

    # https://mynixos.com/nixpkgs/package/mcp-nixos
    # mcp-nixos

    # https://mynixos.com/nixpkgs/package/gitea-mcp-server
    # gitea-mcp-server

    # https://mynixos.com/nixpkgs/package/playwright-mcp
    # playwright-mcp

    # https://mynixos.com/nixpkgs/package/terraform-mcp-server
    # terraform-mcp-server

    # https://mynixos.com/nixpkgs/package/mcp-k8s-go
    # 
    # https://github.com/strowk/mcp-k8s-go
    # https://github.com/containers/kubernetes-mcp-server
    # 
    # mcp-k8s-go

    # https://mynixos.com/nixpkgs/package/aks-mcp-server
    # Azure Kubernetes Service
    # aks-mcp-server

    # https://mynixos.com/nixpkgs/package/mcp-grafana
    # mcp-grafana

    # https://mynixos.com/nixpkgs/package/fluxcd-operator-mcp
    # fluxcd-operator-mcp
  ];
}
