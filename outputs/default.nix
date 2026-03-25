{
  config,
  inputs,
  lib,
  ...
}: let
  supportedSystems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];
  mylib = import ../lib {inherit lib;};
  globals = config.globals;
  customPkgsOverlay = import ../pkgs/overlay.nix;

  mkPkgs = system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      config.nvidia.acceptLicense = true;
      config.allowBroken = true;
      config.enableParallelBuilding = true;
      config.buildManPages = false;
      config.buildDocs = false;
      overlays = [customPkgsOverlay];
    };

  mkPkgsUnstable = system:
    import (inputs.nixpkgs-unstable or inputs.nixpkgs) {
      inherit system;
      config.allowUnfree = true;
      config.allowBroken = true;
      config.enableParallelBuilding = true;
      config.buildManPages = false;
      config.buildDocs = false;
      overlays = [customPkgsOverlay];
    };

  genSpecialArgs = system: {
    inherit inputs mylib globals;
    pkgs = mkPkgs system;
    pkgs-unstable = mkPkgsUnstable system;
  };

  mkSpecialArgs = system: hostMeta:
    (genSpecialArgs system)
    // {
      inherit hostMeta;
      userMeta = hostMeta.user;
      timeMeta = hostMeta.time;
    };

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

  allSystemNames = builtins.attrNames architectureOutputs;
  architectureOutputValues = builtins.attrValues architectureOutputs;
  currentSystem = builtins.currentSystem or null;
  currentSystemValues =
    if currentSystem != null && builtins.hasAttr currentSystem architectureOutputs
    then [architectureOutputs.${currentSystem}]
    else [];
  deployCurrent = {
    nodes = lib.attrsets.mergeAttrsList (map (it: it.deploy.nodes or {}) currentSystemValues);
  };

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
    architectureOutput = architectureOutputs.${system} or {};
    deployChecks =
      if
        currentSystem
        != null
        && system == currentSystem
        && builtins.hasAttr currentSystem inputs."deploy-rs".lib
      then inputs."deploy-rs".lib.${currentSystem}.deployChecks deployCurrent
      else {};
  in {
    _module.args.pkgs = pkgs;

    apps =
      {
        deploy-rs = inputs."deploy-rs".apps.${system}.deploy-rs;
        default = inputs."deploy-rs".apps.${system}.default;
      }
      // (architectureOutput.apps or {})
      // lib.optionalAttrs (
        builtins.hasAttr "packages" inputs.nixos-facter
        && builtins.hasAttr system inputs.nixos-facter.packages
        && builtins.hasAttr "default" inputs.nixos-facter.packages.${system}
      ) {
        nixos-facter = {
          type = "app";
          program = "${inputs.nixos-facter.packages.${system}.default}/bin/nixos-facter";
        };
      };

    checks = deployChecks;

    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        bashInteractive
        gcc
        nixfmt
        deadnix
        statix
        typos
        nodePackages.prettier
      ];
      name = "dots";
    };

    formatter = pkgs.nixfmt;
    packages = architectureOutput.packages or {};
  };

  flake = {
    darwinConfigurations = mergedDarwinConfigurations;
    debugAttrs = {
      inherit
        architectureOutputs
        allSystemNames
        ;
    };
    deploy = {
      nodes = mergedDeployNodes;
    };
    nixosConfigurations = mergedNixosConfigurations;
  };
}
