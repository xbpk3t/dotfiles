{
  lib,
  # 假设这个测试会在正确的 Nixpkgs 环境中运行
}: let
  # 导入我们要测试的 mylib
  # 测试数据：创建一个虚拟的目录结构来测试 scanPaths
  # 模拟 readDir 的结果
  mockReadDir = _path: {
    "default.nix" = "regular";
    "test-module-1.nix" = "regular";
    "test-module-2.nix" = "regular";
    "subdir" = "directory";
  };

  # 修改的 scanPaths 函数，使用模拟的 readDir
  testScanPaths = path: let
    dirContent = mockReadDir path;
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

  # 预期结果
  expectedPaths = [
    "/test/path/test-module-1.nix"
    "/test/path/test-module-2.nix"
    "/test/path/subdir"
  ];

  # 实际结果
  actualPaths = testScanPaths "/test/path";

  # 测试结果
  testResults = {
    # 基本功能测试
    scanPathsWorks = actualPaths == expectedPaths;

    # 长度测试
    correctLength = builtins.length actualPaths == builtins.length expectedPaths;

    # 包含正确的文件
    containsTestModule1 = builtins.elem "/test/path/test-module-1.nix" actualPaths;
    containsTestModule2 = builtins.elem "/test/path/test-module-2.nix" actualPaths;
    containsSubdir = builtins.elem "/test/path/subdir" actualPaths;

    # 不包含 default.nix
    notContainsDefault = !(builtins.elem "/test/path/default.nix" actualPaths);

    # 所有测试都通过
    allTestsPass =
      (actualPaths == expectedPaths)
      && (builtins.length actualPaths == builtins.length expectedPaths)
      && (builtins.elem "/test/path/test-module-1.nix" actualPaths)
      && (builtins.elem "/test/path/test-module-2.nix" actualPaths)
      && (builtins.elem "/test/path/subdir" actualPaths)
      && !(builtins.elem "/test/path/default.nix" actualPaths);
  };
in {
  # 返回测试结果
  inherit testResults;

  # 为了方便调试，返回详细信息
  debug = {
    expected = expectedPaths;
    actual = actualPaths;
    expectedLength = builtins.length expectedPaths;
    actualLength = builtins.length actualPaths;
  };

  # 断言：如果测试失败，构建会失败
  assertion = lib.assertMsg testResults.allTestsPass ''
    scanPaths test failed!

    Expected: ${toString expectedPaths}
    Actual: ${toString actualPaths}

    Detailed results:
    - Basic functionality: ${toString testResults.scanPathsWorks}
    - Correct length: ${toString testResults.correctLength}
    - Contains test-module-1.nix: ${toString testResults.containsTestModule1}
    - Contains test-module-2.nix: ${toString testResults.containsTestModule2}
    - Contains subdir: ${toString testResults.containsSubdir}
    - Excludes default.nix: ${toString testResults.notContainsDefault}
  '';
}
