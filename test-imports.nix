{pkgs, ...}: let
  # 复制你的 mylib 来测试
  mylib = import ./lib/default.nix {lib = pkgs.lib;};

  # 模拟你的 nixos 模块导入
  nixosModules = [
    ../base
    (mylib.scanPaths ./modules/nixos)
  ];

  # 检查具体导入了什么
  servicesDir = ./modules/nixos/services;
  scannedServices = mylib.scanPaths servicesDir;
in {
  # 为了调试，输出一些信息
  system.activationScripts.test-imports.text = ''
    echo "=== 调试信息 ==="
    echo "扫描到的 services 模块:"
    for module in ${toString scannedServices}; do
      echo "  - $module"
    done
    echo "==="
  '';

  # 实际导入测试
  imports = nixosModules;
}
