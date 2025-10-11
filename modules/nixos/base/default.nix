{mylib, ...}: {
  imports = mylib.scanPaths ./.;

  # 使用 nh 来管理垃圾回收，禁用内置的 nix.gc
  nix.gc = {
    automatic = lib.mkDefault false; # 禁用内置 GC，使用 nh 代替
  };

  # Manual optimise storage: nix-store --optimise
  # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  nix.settings.auto-optimise-store = true;

  nix.channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.
}
