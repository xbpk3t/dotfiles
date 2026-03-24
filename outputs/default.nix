{
  self,
  nixpkgs,
  ...
} @ inputs: let
  inherit (inputs.nixpkgs) lib;
  mylib = import ../lib {inherit lib;};
  myvars = import ../vars {inherit lib;};
  customPkgsOverlay = import ../pkgs/overlay.nix;

  # Add my custom lib, vars, nixpkgs instance, and all the inputs to specialArgs,
  # so that I can use them in all my nixos/home-manager/darwin modules.
  genSpecialArgs = system: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      # to install chrome, you need to enable unfree packages
      config.allowUnfree = true;
      # 接受 NVIDIA 驱动license，否则无法build
      config.nvidia.acceptLicense = true;
      # 允许安装 broken 包（如 zig）
      config.allowBroken = true;
      # 全局构建行为（原先在 nixpkgs.config 模块层声明）。
      # NOTE: 在 HM useGlobalPkgs 场景下，把这些配置收敛到 pkgs 构造阶段，
      # 可避免 "nixpkgs.config/overlays will be ignored" 的评估警告。
      config.enableParallelBuilding = true;
      config.buildManPages = false;
      config.buildDocs = false;
      overlays = [
        customPkgsOverlay
      ];
    };
  in {
    inherit
      inputs
      mylib
      myvars
      pkgs
      ;

    # use unstable branch for some packages to get the latest updates
    pkgs-unstable = import inputs.nixpkgs-unstable or inputs.nixpkgs {
      inherit system; # refer the `system` parameter form outer scope recursively
      # To use chrome, we need to allow the installation of non-free software
      config.allowUnfree = true;
      config.allowBroken = true;
      config.enableParallelBuilding = true;
      config.buildManPages = false;
      config.buildDocs = false;
      overlays = [
        customPkgsOverlay
      ];
    };
  };

  # This is the args for all the haumea modules in this folder.
  args = inputs: {
    inherit
      inputs
      lib
      mylib
      myvars
      genSpecialArgs
      ;
  };

  # modules for each supported system
  darwinSystems = {
    aarch64-darwin = import ./aarch64-darwin (args inputs
      // {
        system = "aarch64-darwin";
        inherit self;
      });
  };
  linuxSystems = {
    aarch64-linux = import ./aarch64-linux (args inputs
      // {
        system = "aarch64-linux";
        inherit self;
      });
    x86_64-linux = import ./x86_64-linux (args inputs
      // {
        system = "x86_64-linux";
        inherit self;
      });
  };
  allSystems = darwinSystems // linuxSystems;
  allSystemNames = builtins.attrNames allSystems;
  darwinSystemValues = builtins.attrValues darwinSystems;
  linuxSystemValues = builtins.attrValues linuxSystems;
  allSystemValues = darwinSystemValues ++ linuxSystemValues;
  # NOTE: deploy-rs 的 checks 在“当前机器”执行。
  # Why：在 Linux 上去 check/build darwin profile 会报
  #      “Required system: aarch64-darwin”。因此 checks 必须限制在本机系统。
  # What：deploy 仍暴露全平台节点用于跨平台部署，但 checks 仅覆盖当前系统。
  currentSystem = builtins.currentSystem or null;
  currentSystemValues =
    if currentSystem != null && builtins.hasAttr currentSystem allSystems
    then [allSystems.${currentSystem}]
    else [];
  # Why：deployChecks 会构建可激活的 profile，必须是本机可构建的系统。
  # What：为 checks 构造一个“仅当前系统节点”的 deploy 视图。
  deployCurrent = {
    nodes = lib.attrsets.mergeAttrsList (map (it: it.deploy.nodes or {}) currentSystemValues);
  };

  # Helper function to generate a set of attributes for each system
  forAllSystems = func: (nixpkgs.lib.genAttrs allSystemNames func);

  # Default system used for running Namaka snapshot tests.
  namakaTestSystem = "x86_64-linux";
  namakaTestSpecialArgs = genSpecialArgs namakaTestSystem;
in {
  # Add attribute sets into outputs, for debugging
  debugAttrs = {
    inherit
      darwinSystems
      linuxSystems
      allSystems
      allSystemNames
      ;
  };

  # NixOS Hosts
  nixosConfigurations = lib.attrsets.mergeAttrsList (
    map (it: it.nixosConfigurations or {}) linuxSystemValues
  );

  # macOS Hosts
  darwinConfigurations = lib.attrsets.mergeAttrsList (
    map (it: it.darwinConfigurations or {}) darwinSystemValues
  );

  # Packages
  packages = forAllSystems (system: allSystems.${system}.packages or {});

  # Apps
  apps = forAllSystems (system: {
    # Why：把 deploy-rs CLI 挂到当前仓库 flake 输出上，避免 task 直接
    #      `nix run github:serokell/deploy-rs` 时绕开本仓库的 flake.lock。
    # What：透传已 pin 的 deploy-rs app；后续统一用 `nix run .#deploy-rs`。
    deploy-rs = inputs."deploy-rs".apps.${system}.deploy-rs;
    # Why：保留 default app 作为兼容入口，便于手动 `nix run .` 或外部复用。
    default = inputs."deploy-rs".apps.${system}.default;
  });

  # Eval Tests for all systems.
  evalTests = lib.lists.all (it: it.evalTests == {}) allSystemValues;

  # Namaka snapshot tests evaluate the fixtures under ./tests via haumea.
  checks =
    (inputs.namaka.lib.load {
      src = self + "/tests/haumea";
      inputs = {
        inherit lib;
        inherit (inputs) haumea;
        pkgs = namakaTestSpecialArgs.pkgs;
      };
    })
    // (
      # Why：deployChecks 会构建可激活 profile；跨系统（如 Linux 上构建 darwin）
      #      在本机不可构建。
      # What：只对当前系统生成 deployChecks，并使用仅含本机节点的 deploy 视图。
      if currentSystem != null && builtins.hasAttr currentSystem inputs."deploy-rs".lib
      then {
        ${currentSystem} = inputs."deploy-rs".lib.${currentSystem}.deployChecks deployCurrent;
      }
      else {}
    );

  # Development Shells
  devShells = forAllSystems (
    system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          # fix https://discourse.nixos.org/t/non-interactive-bash-errors-from-flake-nix-mkshell/33310
          bashInteractive
          # fix `cc` replaced by clang, which causes nvim-treesitter compilation error
          gcc
          # Nix-related
          nixfmt
          deadnix
          statix
          # spell checker
          typos
          # code formatter
          nodePackages.prettier
          # namaka for snapshot testing
          inputs.namaka.packages.${system}.default
        ];
        name = "dots";
        # inherit (self.checks.${system}.pre-commit-check) shellHook;
      };
    }
  );

  # Format the nix code in this flake
  formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

  # deploy-rs deployment nodes are provided by each host file.
  # https://github.com/serokell/deploy-rs
  deploy = {
    # Why：允许在同一入口下发跨平台部署（Linux + darwin + 其他 profile）。
    # What：合并所有系统节点到 deploy.nodes；checks 已在上方限制为当前系统。
    nodes = lib.attrsets.mergeAttrsList (map (it: it.deploy.nodes or {}) allSystemValues);
  };
}
