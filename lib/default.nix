{ lib, ... }:
let
  # Import all library functions
  macosSystem = import ./macos.nix;
  nixosSystem = import ./nixos.nix;
  # sm-vps 平行轨：standalone Home Manager + system-manager
  homeStandalone = import ./home-standalone.nix;
  systemManager = import ./system-manager.nix;
  # 提供统一的节点 ID / host meta 生成器
  inventory = import ./inventory { inherit lib; };
  vpsSysctl = import ./vps-sysctl.nix { inherit lib; };
  nixCacheSettings = import ./nix-cache-settings.nix;
  # pre-commit 依赖工具集（单一事实来源，devShell 与 home.packages 共用）
  precommitTools = import ./precommit-tools.nix;

  # use path relative to the root of the project
  relativeToRoot = lib.path.append ../.;
  facter = import ./facter.nix {
    inherit relativeToRoot;
  };
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
    homeStandalone
    systemManager
    inventory
    vpsSysctl
    nixCacheSettings
    precommitTools
    facter
    scanPaths
    relativeToRoot
    ;
}
