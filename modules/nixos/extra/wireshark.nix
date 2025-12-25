{
  config,
  lib,
  myvars,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.programs.wireshark.enable;
in {
  # https://mynixos.com/nixpkgs/options/programs.wireshark
  # https://mynixos.com/nixpkgs/package/wireshark
  programs.wireshark = {
    enable = true;
    # Whether to allow users in the 'wireshark' group to capture network traffic(via a setcap wrapper).
    dumpcap.enable = true;
    # Whether to allow users in the 'wireshark' group to capture USB traffic (via udev rules).
    usbmon.enable = false;
  };

  users.groups = mkIf cfg {wireshark = {};};
  users.users."${myvars.username}".extraGroups = mkIf cfg ["wireshark"];
}
