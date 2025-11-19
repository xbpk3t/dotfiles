{lib, ...}: let
  # Import all library functions
  macosSystem = import ./macos.nix;
  nixosSystem = import ./nixos.nix;
  colmenaSystem = import ./colmena-system.nix;
  composeLib = import ./compose.nix {inherit lib;};
  attrs = import ./attrs.nix {inherit lib;};
  ingressOption = import ./ingress-option.nix {inherit lib;};
  ingressUtils = import ./ingress-utils.nix {inherit lib;};

  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;
  # Custom utilities
  scanPaths = path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          path: _type:
            (_type == "directory") # include directories
            || (
              (path != "default.nix") # ignore default.nix
              && (lib.strings.hasSuffix ".nix" path) # include .nix files
            )
        ) (builtins.readDir path)
      )
    );
in (
  {
    inherit
      macosSystem
      nixosSystem
      colmenaSystem
      attrs
      ingressOption
      scanPaths
      relativeToRoot
      ;
  }
  // ingressUtils
  // composeLib
)
