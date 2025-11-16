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
    x86_64-darwin = import ./x86_64-darwin (args inputs
      // {
        system = "x86_64-darwin";
        inherit self;
      });
  };
  linuxSystems = {
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

  # Eval Tests for all systems.
  evalTests = lib.lists.all (it: it.evalTests == {}) allSystemValues;

  # Namaka snapshot tests evaluate the fixtures under ./tests via haumea.
  checks = inputs.namaka.lib.load {
    src = self + "/tests/haumea";
    inputs = {
      inherit lib;
      inherit (inputs) haumea;
      pkgs = namakaTestSpecialArgs.pkgs;
    };
  };

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

  # Colmena deployment configuration
  # https://colmena.cli.rs/unstable/introduction.html
  # 使用方法: colmena apply
  # 注意: 需要先配置 SSH 密钥认证到目标机器的 root 用户
  colmena = {
    meta = {
      nixpkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      specialArgs = genSpecialArgs "x86_64-linux";
    };

    # NixOS workstation - 远程部署目标
    nixos-ws = {
      deployment = {
        targetHost = "192.168.234.194";
        targetUser = "luck";
        # 使用 SSH 密钥认证（需要配置 SSH 密钥）
        # buildOnTarget = true; # 在目标机器上构建，避免跨架构问题
      };

      # 直接导入 nixos-ws 的配置模块
      # 这样 colmena 会使用与 nixosConfigurations.nixos-ws 相同的配置
      imports = mylib.relativeToRoot [
        "hosts/nixos-ws/default.nix"
        "secrets/default.nix"
        "modules/base"
        "modules/nixos/base"
        "modules/nixos/desktop"
      ];
    };

    nixos-vps = let
      target =
        myvars.networking.colmenaTargets.nixos-vps
        or {
          targetHost = "127.0.0.1";
          targetUser = "root";
        };
    in {
      deployment = {
        inherit (target) targetHost targetUser;
        targetPort = target.targetPort or null;
      };

      imports = map mylib.relativeToRoot [
        "hosts/nixos-vps/default.nix"
        "modules/base"
        "modules/nixos/base"
        "modules/nixos/vps"
      ];
    };
  };
}
