{mylib, ...}: let
  cntrSource = mylib.relativeToRoot ".cntr";
in {
  # Ship the entire cntr directory into the user's home so docker compose
  # stacks can be managed imperatively on any host without relying on a local checkout.
  home.file.".cntr" = {
    source = cntrSource;
    recursive = true;
  };
}
