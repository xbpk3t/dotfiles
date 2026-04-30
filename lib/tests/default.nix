{
  pkgs,
  lib ? pkgs.lib,
}: let
  # 注意：这里把“可 import 的测试表达式”包装成真正的 derivation，
  # 这样它们才能进入 flake `checks`，成为默认质量闸门的一部分。
  mkEvalCheck = name: testFile: let
    testResult = import testFile {inherit lib;};
  in
    assert testResult.assertion;
      pkgs.writeText "${name}.json" (builtins.toJSON testResult.testResults);
in {
  # 纯逻辑测试：验证 `scanPaths` 的过滤规则是否符合预期。
  scan-paths = mkEvalCheck "scan-paths-test" ./scan-paths-test.nix;

  # 真实目录测试：验证仓库里的 services tree 仍然满足 `scanPaths` 的契约。
  real-scan-paths = mkEvalCheck "real-scan-paths-test" ./real-scan-paths-test.nix;

  # 代理协议生成：验证 singbox / mihomo outbounds 会为新增协议生成节点。
  proxy-outbounds = mkEvalCheck "proxy-outbounds-test" ./proxy-outbounds-test.nix;
}
