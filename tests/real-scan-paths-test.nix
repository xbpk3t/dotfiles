{
  lib ? import <nixpkgs/lib>,
}:
let
  mylib = import ../lib/default.nix { inherit lib; };

  # 使用当前仓库里真实存在、并且确实通过 `scanPaths` 聚合 imports 的目录。
  # 注：`modules/nixos/base` 已在重构中拆走（base 逻辑并入 home/base），
  # 该路径不存在；这里改用同样用 scanPaths 合同聚合的 modules/nixos/kernel
  # （含 core.nix / security.nix，default.nix 应被排除）。
  baseModulesPath = ../modules/nixos/kernel;

  # 使用真实的 scanPaths 函数
  scanResult = mylib.scanPaths baseModulesPath;

  # 直接计算测试结果避免循环引用
  containsCore = builtins.elem (baseModulesPath + "/core.nix") scanResult;
  containsSecurity = builtins.elem (baseModulesPath + "/security.nix") scanResult;
  containsDefault = builtins.elem (baseModulesPath + "/default.nix") scanResult;
  notEmpty = scanResult != [ ];
  allTestsPass = notEmpty && containsCore && containsSecurity && !containsDefault;
in
{
  # 返回测试结果
  testResults = {
    inherit
      containsCore
      containsSecurity
      containsDefault
      notEmpty
      allTestsPass
      ;
  };

  # 断言
  assertion = lib.assertMsg allTestsPass ''
    Real scanPaths test failed!

    Scanned ${toString (builtins.length scanResult)} files:
    ${toString scanResult}

    Critical issues:
    - core.nix found: ${toString containsCore}
    - security.nix found: ${toString containsSecurity}
    - Default.nix correctly excluded: ${toString (if !containsDefault then "true" else "false")}
    - Scan result not empty: ${toString notEmpty}
  '';
}
