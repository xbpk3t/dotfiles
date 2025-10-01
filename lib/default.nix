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
          # Include directories only if they have a default.nix file
            ((_type == "directory") && (builtins.pathExists (path + "/${name}/default.nix")))
            || (
              # Include .nix files except default.nix
              (name != "default.nix")
              && (lib.strings.hasSuffix ".nix" name)
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
