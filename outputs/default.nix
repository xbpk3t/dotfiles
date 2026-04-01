{
  config,
  inputs,
  lib,
  ...
}: let
  # 当前仓库明确支持的 target systems。
  # why: flake-parts 的 perSystem 会基于这里展开；这里是顶层支持矩阵的单一入口。
  supportedSystems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];

  # 仓库内自定义 lib，供 hosts/modules/home 共享。
  mylib = import ../lib {inherit lib;};
  globals = config.globals;
  customPkgsOverlay = import ../pkgs/overlay.nix;

  # 单通道 rolling pkgs：作为系统构建与 Home Manager 的主 pkgs 实例。
  # 注意：
  # - overlays 统一在这里注入，避免各 host 重复写。
  # - allowUnfree / allowBroken 等策略也统一收口在这里。
  # - 当前仓库只保留一套 pkgs，避免“名义双通道，实际同源”的虚假抽象。
  # - 分支策略统一交给 flake inputs；这里不再重复制造 stable/unstable 概念。
  mkPkgs = system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.nvidia.acceptLicense = true;
      # 默认禁止 broken packages。
      # Why: broken package 应该是显式例外，而不是整仓默认吞掉风险信号。
      config.allowBroken = false;
      config.enableParallelBuilding = true;
      config.buildManPages = false;
      config.buildDocs = false;
      overlays = [customPkgsOverlay];
    };

  # 共享给 nixos/darwin/home modules 的基础 specialArgs。
  # 注意：这里只透传一套 pkgs。
  # Why: 仓库当前明确采用单通道模型，模块侧不再接触第二套 pkgs 入口。
  genSpecialArgs = system: {
    inherit inputs mylib globals;
    pkgs = mkPkgs system;
  };

  # host-aware specialArgs：在基础 specialArgs 之上补齐当前主机的身份信息。
  # why: user/time/networking 等主机差异数据不应散落在各模块里手写。
  mkSpecialArgs = system: hostMeta:
    (genSpecialArgs system)
    // {
      inherit hostMeta;
      userMeta = hostMeta.user;
      timeMeta = hostMeta.time;
      # Why: outputs/default.nix 只负责把 host metadata 分发给模块，
      # 不再在 wiring 层硬编码 editor 偏好值；editor 的真实来源固定为 hostMeta.editor。
      editorMeta = hostMeta.editor;
    };

  # 传给 outputs/<system>/src/*.nix 的公共参数。
  baseOutputArgs = {
    inherit
      inputs
      lib
      mylib
      globals
      genSpecialArgs
      mkSpecialArgs
      ;
  };

  # 加载某一架构目录下的 role outputs，并注入公共参数。
  loadRoleOutputs = dir: extraArgs: let
    outputFiles =
      builtins.map (name: dir + "/${name}")
      (builtins.filter
        (name:
          name
          != "default.nix"
          && lib.strings.hasSuffix ".nix" name)
        (builtins.attrNames (builtins.readDir dir)));
  in
    map (path: import path (baseOutputArgs // extraArgs)) outputFiles;

  # 将同一架构下多个 output 文件合并为一份标准输出结构。
  mergeRoleOutputList = outputs: {
    apps = lib.attrsets.mergeAttrsList (map (it: it.apps or {}) outputs);
    darwinConfigurations = lib.attrsets.mergeAttrsList (
      map (it: it.darwinConfigurations or {}) outputs
    );
    deploy = {
      nodes = lib.attrsets.mergeAttrsList (map (it: it.deploy.nodes or {}) outputs);
    };
    nixosConfigurations = lib.attrsets.mergeAttrsList (
      map (it: it.nixosConfigurations or {}) outputs
    );
    packages = lib.attrsets.mergeAttrsList (map (it: it.packages or {}) outputs);
  };

  # 三套架构分别收敛成统一输出。
  architectureOutputs = {
    aarch64-darwin = mergeRoleOutputList (loadRoleOutputs ./aarch64-darwin/src {
      system = "aarch64-darwin";
    });
    aarch64-linux = mergeRoleOutputList (loadRoleOutputs ./aarch64-linux/src {
      system = "aarch64-linux";
    });
    x86_64-linux = mergeRoleOutputList (loadRoleOutputs ./x86_64-linux/src {
      system = "x86_64-linux";
    });
  };

  architectureOutputValues = builtins.attrValues architectureOutputs;
  currentSystem = builtins.currentSystem or null;

  # deploy-rs 的 deployChecks 只对“当前求值系统”运行。
  # why: deploy-rs 的检查实现按 system 分发，跨系统强行求值没有收益，还会引入噪音。
  currentSystemValues =
    if currentSystem != null && builtins.hasAttr currentSystem architectureOutputs
    then [architectureOutputs.${currentSystem}]
    else [];

  # 仅收敛当前系统的 deploy nodes，供 deployChecks 使用。
  deployCurrent = {
    nodes = lib.attrsets.mergeAttrsList (map (it: it.deploy.nodes or {}) currentSystemValues);
  };

  # flake 顶层需要汇总后的 darwin/nixos/deploy outputs。
  mergedNixosConfigurations = lib.attrsets.mergeAttrsList (
    map (it: it.nixosConfigurations or {}) architectureOutputValues
  );
  mergedDarwinConfigurations = lib.attrsets.mergeAttrsList (
    map (it: it.darwinConfigurations or {}) architectureOutputValues
  );
  mergedDeployNodes = lib.attrsets.mergeAttrsList (
    map (it: it.deploy.nodes or {}) architectureOutputValues
  );
in {
  systems = supportedSystems;

  perSystem = {system, ...}: let
    specialArgs = genSpecialArgs system;
    pkgs = specialArgs.pkgs;
    architectureOutput = architectureOutputs.${system};
    libChecks = import ../lib/tests {
      inherit pkgs;
      lib = pkgs.lib;
    };

    # deploy-rs 官方推荐把 deployChecks 接到 flake checks。
    # 注意：这里只在当前 system 上启用，避免无意义的跨系统检查。
    deployChecks =
      if
        currentSystem
        != null
        && system == currentSystem
        && builtins.hasAttr currentSystem inputs."deploy-rs".lib
      then inputs."deploy-rs".lib.${currentSystem}.deployChecks deployCurrent
      else {};
  in {
    # flake apps:
    # - deploy-rs: 统一部署入口
    # - nixos-facter: 直接暴露 fact collection CLI，便于 `nix run .#nixos-facter`
    apps =
      {
        deploy-rs = inputs."deploy-rs".apps.${system}.deploy-rs;
        default = inputs."deploy-rs".apps.${system}.default;
      }
      // architectureOutput.apps
      // lib.optionalAttrs (
        pkgs.stdenv.hostPlatform.isLinux
        && builtins.hasAttr "packages" inputs.nixos-facter
        && builtins.hasAttr system inputs.nixos-facter.packages
        && builtins.hasAttr "default" inputs.nixos-facter.packages.${system}
      ) {
        nixos-facter = {
          type = "app";
          program = "${inputs.nixos-facter.packages.${system}.default}/bin/nixos-facter";
        };
      };

    # 注意：`checks` 是仓库默认质量闸门的统一入口。
    # deploy-rs checks 负责 deployment safety，libChecks 负责仓库内的基础回归测试。
    checks = deployChecks // libChecks;

    # `nix fmt` / flake formatter 的统一入口。
    formatter = pkgs.nixfmt;
    packages = architectureOutput.packages;
  };

  flake = {
    darwinConfigurations = mergedDarwinConfigurations;
    deploy = {
      nodes = mergedDeployNodes;
    };
    nixosConfigurations = mergedNixosConfigurations;
  };
}
