{lib ? import <nixpkgs/lib>}: let
  mylib = import ../default.nix {inherit lib;};

  # 使用当前仓库里真实存在、并且确实通过 `scanPaths` 聚合 imports 的目录。
  baseModulesPath = ./../../modules/nixos/base;

  # 使用真实的 scanPaths 函数
  scanResult = mylib.scanPaths baseModulesPath;

  # 检查关键文件是否存在

  # 预期的结果（不包括 default.nix）

  # 实际结果中应该包含的文件
  shouldContain = [
    (baseModulesPath + "/core.nix")
    (baseModulesPath + "/security.nix")
  ];

  # 实际结果中不应该包含的文件
  shouldNotContain = [
    (baseModulesPath + "/default.nix")
  ];

  # 直接计算测试结果避免循环引用
  containsCore = builtins.elem (baseModulesPath + "/core.nix") scanResult;
  containsSecurity = builtins.elem (baseModulesPath + "/security.nix") scanResult;
  containsDefault = builtins.elem (baseModulesPath + "/default.nix") scanResult;
  notEmpty = scanResult != [];
  allTestsPass =
    scanResult
    != []
    && (builtins.elem (baseModulesPath + "/core.nix") scanResult)
    && (builtins.elem (baseModulesPath + "/security.nix") scanResult)
    && !(builtins.elem (baseModulesPath + "/default.nix") scanResult);
in {
  # 返回测试结果
  testResults = {
    inherit containsCore containsSecurity containsDefault notEmpty allTestsPass;
  };

  # 调试信息
  debug = {
    scanResultLength = builtins.length scanResult;
    shouldContain = shouldContain;
    shouldNotContain = shouldNotContain;
    baseModulesPath = toString baseModulesPath;
    inherit containsCore containsSecurity containsDefault notEmpty;
    allTestsPass = allTestsPass;
  };

  # 断言
  assertion = lib.assertMsg allTestsPass ''
    Real scanPaths test failed!

    Scanned ${toString (builtins.length scanResult)} files:
    ${toString scanResult}

    Critical issues:
    - core.nix found: ${toString containsCore}
    - security.nix found: ${toString containsSecurity}
    - Default.nix correctly excluded: ${toString (
      if !containsDefault
      then "true"
      else "false"
    )}
    - Scan result not empty: ${toString notEmpty}
  '';

  # 更详细的失败信息
  detailedAssertion = lib.assertMsg allTestsPass ''
    scanPaths function verification failed.

    Expected behavior:
    - Should find core.nix: ${
      if containsCore
      then "✅"
      else "❌"
    }
    - Should find security.nix: ${
      if containsSecurity
      then "✅"
      else "❌"
    }
    - Should exclude default.nix: ${
      if !containsDefault
      then "✅"
      else "❌"
    }
    - Should not be empty: ${
      if notEmpty
      then "✅"
      else "❌"
    }

    This means your base modules ${
      if allTestsPass
      then "ARE"
      else "are NOT"
    } being imported correctly.
  '';
}
