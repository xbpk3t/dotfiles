{
  lspPkgs = pkgs:
    with pkgs; [
      # zed的nix LSP需要nixd
      # https://mynixos.com/nixpkgs/package/nixd
      nixd
      nil
      rustfmt
      rust-analyzer
    ];
}
