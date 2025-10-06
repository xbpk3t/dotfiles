{
  self,
  nixpkgs,
  ...
} @ inputs: let
  inherit (inputs.nixpkgs) lib;
  mylib = import ../lib {inherit lib;};
  myvars = import ../vars {inherit lib;};

  # Add my custom lib, vars, nixpkgs instance, and all the inputs to specialArgs,
  # so that I can use them in all my nixos/home-manager/darwin modules.
  genSpecialArgs = system: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      # 接受 NVIDIA 驱动license，否则无法build
      config.nvidia.acceptLicense = true;
    };
  in {
    inherit
      mylib
      myvars
      pkgs
      ;

    # use unstable branch for some packages to get the latest updates
    pkgs-unstable = import inputs.nixpkgs-unstable or inputs.nixpkgs {
      inherit system; # refer the `system` parameter form outer scope recursively
      # To use chrome, we need to allow the installation of non-free software
      config.allowUnfree = true;
    };

    # Add anyrun for anyrun configuration modules
    anyrun = inputs.anyrun;

    # Add catppuccin for theme configuration
    catppuccin = inputs.catppuccin;

    # Add nixvim for neovim configuration
    nixvim = inputs.nixvim;

    # Add vicinae for application launcher
    vicinae = inputs.vicinae;

    # Add sops-nix for secret management
    sops-nix = inputs.sops-nix;
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

  # TODO: Add proper checks when needed
  # checks = forAllSystems (system: {
  #   # eval-tests per system
  #   eval-tests = allSystems.${system}.evalTests == { };
  # });
  checks = {};

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
        ];
        name = "dots";
        # inherit (self.checks.${system}.pre-commit-check) shellHook;
      };
    }
  );

  # Format the nix code in this flake
  formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
}
