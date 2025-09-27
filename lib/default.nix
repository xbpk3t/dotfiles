{lib, ...}: let
  # Import all library functions
  macosSystem = import ./macos.nix;
  nixosSystem = import ./nixos.nix;
  attrs = import ./attrs.nix {inherit lib;};

  # Custom utilities
  scanPaths = path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          name: _type:
            (_type == "directory") # include directories
            || (
              (name != "default.nix") # ignore default.nix
              && (lib.strings.hasSuffix ".nix" name) # include .nix files
            )
        ) (builtins.readDir path)
      )
    );

  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;
in {
  inherit
    macosSystem
    nixosSystem
    attrs
    scanPaths
    relativeToRoot
    ;
}
