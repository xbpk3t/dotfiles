{lib, ...}: let
  # Import all library functions
  macosSystem = import ./macos.nix;
  nixosSystem = import ./nixos.nix;
  # 提供统一的节点 ID / host meta 生成器，供 colmena/nixos 模块复用
  node = import ./node-id.nix {inherit lib;};
  colmenaSystem = import ./colmena-system.nix;
  mkColmenaRole = import ./mkColmenaRole.nix;
  attrs = import ./attrs.nix {inherit lib;};

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
in {
  inherit
    macosSystem
    nixosSystem
    colmenaSystem
    mkColmenaRole
    node
    attrs
    scanPaths
    relativeToRoot
    ;
}
