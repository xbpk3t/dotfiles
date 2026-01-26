{ lib, ... }:
let
  # Import all library functions
  macosSystem = import ./macos.nix;
  nixosSystem = import ./nixos.nix;
  # 提供统一的节点 ID / host meta 生成器
  node = import ./node-id.nix { inherit lib; };
  inventory = import ./inventory.nix { inherit lib; };
  attrs = import ./attrs.nix { inherit lib; };
  langs = import ./langs.nix;
  nettune = import ./vps-nettune.nix { inherit lib; };

  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;
  # Custom utilities
  scanPaths =
    path:
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
in
{
  inherit
    macosSystem
    nixosSystem
    node
    inventory
    attrs
    langs
    nettune
    scanPaths
    relativeToRoot
    ;
}
