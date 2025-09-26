let
  lib = import <nixpkgs/lib>;

  # 你的 scanPaths 函数
  mylib = {
    scanPaths = path:
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
  };

  # 测试 scanPaths 在 services 目录上的表现
  servicesPath = ./modules/nixos/services;
  scanResult = mylib.scanPaths servicesPath;
in {
  result = scanResult;
  pathType = builtins.typeOf scanResult;
  resultLength = builtins.length scanResult;

  # 检查第一个路径是否存在
  firstPathExists =
    if scanResult != []
    then builtins.pathExists (builtins.elemAt scanResult 0)
    else "empty";
}
