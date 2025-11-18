{lib, ...}: {
  # https://mynixos.com/nixpkgs/options/services.logind

  # Keep a minimal set of local VTs ready on every NixOS machine.
  services.logind.settings.Login = {
    NAutoVTs = lib.mkDefault 2; # auto-spawn getty on tty1/tty2 only
    ReserveVT = lib.mkDefault 1; # keep tty1 reserved so it's always usable
  };
}
