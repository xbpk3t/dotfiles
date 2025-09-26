{lib ? import <nixpkgs/lib>}: let
  mylib = import ../default.nix {inherit lib;};

  # 测试真实的 services 目录
  servicesPath = ./../../modules/nixos/services;

  # 使用真实的 scanPaths 函数
  scanResult = mylib.scanPaths servicesPath;

  # 检查关键文件是否存在

  # 预期的结果（不包括 default.nix）

  # 实际结果中应该包含的文件
  shouldContain = [
    (servicesPath + "/sddm.nix")
    (servicesPath + "/xserver.nix")
  ];

  # 实际结果中不应该包含的文件
  shouldNotContain = [
    (servicesPath + "/default.nix")
  ];

  # 直接计算测试结果避免循环引用
  containsSddm = builtins.elem (servicesPath + "/sddm.nix") scanResult;
  containsXserver = builtins.elem (servicesPath + "/xserver.nix") scanResult;
  containsDefault = builtins.elem (servicesPath + "/default.nix") scanResult;
  notEmpty = scanResult != [];
  allTestsPass =
    scanResult
    != []
    && (builtins.elem (servicesPath + "/sddm.nix") scanResult)
    && (builtins.elem (servicesPath + "/xserver.nix") scanResult)
    && !(builtins.elem (servicesPath + "/default.nix") scanResult);
in {
  # 返回测试结果
  testResults = {
    inherit containsSddm containsXserver containsDefault notEmpty allTestsPass;
  };

  # 调试信息
  debug = {
    scanResultLength = builtins.length scanResult;
    shouldContain = shouldContain;
    shouldNotContain = shouldNotContain;
    servicesPath = toString servicesPath;
    inherit containsSddm containsXserver containsDefault notEmpty;
    allTestsPass = allTestsPass;
  };

  # 断言
  assertion = lib.assertMsg allTestsPass ''
    Real scanPaths test failed!

    Scanned ${toString (builtins.length scanResult)} files:
    ${toString scanResult}

    Critical issues:
    - SDDM module found: ${toString containsSddm}
    - Xserver module found: ${toString containsXserver}
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
    - Should find sddm.nix: ${
      if containsSddm
      then "✅"
      else "❌"
    }
    - Should find xserver.nix: ${
      if containsXserver
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

    This means your services modules ${
      if allTestsPass
      then "ARE"
      else "are NOT"
    } being imported correctly.
  '';
}
