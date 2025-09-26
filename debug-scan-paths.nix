let
  lib = import <nixpkgs/lib>;

  # 你的 scanPaths 函数
  myScanPaths = path:
    builtins.map (f: (path + "/${f}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          path: _type:
            (_type == "directory") # include directories
            || (
              (path != "default.nix") # ignore default.nix
              && (lib.strings.hasSuffix ".nix" path)
            )
        ) (builtins.readDir path)
      )
    );

  # 修正的 scanPaths 函数（修复参数名混淆问题）
  fixedScanPaths = path: let
    dirContent = builtins.readDir path;
    filteredNames = builtins.attrNames (
      lib.attrsets.filterAttrs (
        name: type:
          (type == "directory") # include directories
          || (
            (name != "default.nix") # ignore default.nix
            && (lib.strings.hasSuffix ".nix" name)
          )
      )
      dirContent
    );
  in
    builtins.map (name: path + "/${name}") filteredNames;

  servicesPath = ./modules/nixos/services;
in {
  # 你的版本输出
  myResult = myScanPaths servicesPath;

  # 修正版本输出
  fixedResult = fixedScanPaths servicesPath;

  # 直接列出目录内容对比
  dirContent = builtins.readDir servicesPath;
}
