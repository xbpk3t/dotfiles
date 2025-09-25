{
  pkgs,
  username,
  profile,
  ...
}: {
  home.packages = [
    (import ./hm-find.nix {inherit pkgs;})
    (import ./keybinds.nix {inherit pkgs;})
    (import ./note.nix {inherit pkgs;})
    (import ./note-from-clipboard.nix {inherit pkgs;})
    (import ./nvidia-offload.nix {inherit pkgs;})
    (import ./rofi-launcher.nix {inherit pkgs;})
    (import ./screenshootin.nix {inherit pkgs;})
    (import ./squirtle.nix {inherit pkgs;})
    (import ./task-waybar.nix {inherit pkgs;})
    (import ./wallsetter.nix {
      inherit pkgs;
      inherit username;
    })
    (import ./web-search.nix {inherit pkgs;})
    (import ./zcli.nix {
      inherit pkgs profile;
      backupFiles = [
        ".config/mimeapps.list.backup"
      ];
    })
  ];
}
