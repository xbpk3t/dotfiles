{pkgs, ...}: {

  # FIXME https://github.com/numtide/nix-ai-tools
  home.packages = with pkgs; [
    # tokei # count lines of code, alternative to cloc

    # ai related
    # python313Packages.huggingface-hub # huggingface-cli

    # solve coding extercises - learn by doing
    # exercism

    # need to run `conda-install` before using it
    # need to run `conda-shell` before using command `conda`
    # conda is not available for MacOS
    # conda
  ];
}
