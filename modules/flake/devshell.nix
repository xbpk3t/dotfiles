{ pkgs, ... }: {
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      name = "dotfiles-nu-shell";
      meta.description = "Dev shell for dotfiles NU migration";
      packages = with pkgs; [
        just
        nixd
      ];
    };
  };
}
