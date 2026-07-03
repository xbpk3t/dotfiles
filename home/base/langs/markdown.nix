{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      # python313Packages.markitdown
      # docling
      mdq

      markdownlint-cli
      # doxx
    ];
  };
}
