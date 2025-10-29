{
  pkgs,
  config,
  myvars,
  ...
}: 
let
  fuzzelPath = "${myvars.projectRoot}/home/nixos/gui/fuzzel";
in {
  home.packages = with pkgs; [
    raffi
    cliphist
    wl-clipboard
  ];

  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        dpi-aware = "auto";
        lines = 6;
        prompt = "> ";
        icon-theme = "Papirus-Dark"; # 确保图标显示
      };
      key-bindings = {
        cancel = "Escape Control+g";
      };
    };
  };

  home.activation.linkRaffiScripts = config.lib.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/.local/bin

    ln -sf ${fuzzelPath}/raffi-bookmark.nu $HOME/.local/bin/raffi-bookmark
    chmod +x $HOME/.local/bin/raffi-bookmark

    ln -sf ${fuzzelPath}/raffi-pwgen.nu $HOME/.local/bin/raffi-pwgen
    chmod +x $HOME/.local/bin/raffi-pwgen

    ln -sf ${fuzzelPath}/raffi-snippet.nu $HOME/.local/bin/raffi-snippet
    chmod +x $HOME/.local/bin/raffi-snippet

    ln -sf ${fuzzelPath}/raffi-gh.nu $HOME/.local/bin/raffi-gh
    chmod +x $HOME/.local/bin/raffi-gh

    ln -sf ${fuzzelPath}/raffi-cc.nu $HOME/.local/bin/raffi-cc
    chmod +x $HOME/.local/bin/raffi-cc

    ln -sf ${fuzzelPath}/raffi-common.nu $HOME/.local/bin/raffi-common.nu
    # No chmod +x needed here

    ln -sf ${fuzzelPath}/fuzzel-clipboard.nu $HOME/.local/bin/fuzzel-clipboard
    chmod +x $HOME/.local/bin/fuzzel-clipboard

    ln -sf ${fuzzelPath}/fuzzel-text-actions.nu $HOME/.local/bin/fuzzel-text-actions
    chmod +x $HOME/.local/bin/fuzzel-text-actions
  '';

  xdg.configFile."raffi/raffi.yaml".source = config.lib.file.mkOutOfStoreSymlink "${fuzzelPath}/raffi.yml";
}
