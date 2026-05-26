{
  inputs,
  lib,
  mylib,
  userMeta,
  globals,
  hostMeta,
  timeMeta,
  editorMeta,
  ...
}: let
  agentNodes = mylib.inventory.nodesForContainerHost "nixos-agent" hostMeta.hostName;
  agentNode = agentNodes.nixos-agent or null;
  agentEnabled = agentNode != null;
  agentUserMeta = agentNode.user or userMeta;
  agentTimeMeta = agentNode.time or timeMeta;
  agentEditorMeta = agentNode.editor or editorMeta;
in
  lib.mkIf agentEnabled {
    containers.nixos-agent = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.233.0.1";
      localAddress = agentNode.primaryIp or "10.233.0.2";
      specialArgs = {
        inherit inputs mylib globals;
        hostMeta = agentNode;
        userMeta = agentUserMeta;
        timeMeta = agentTimeMeta;
        editorMeta = agentEditorMeta;
      };
      config = {
        nixpkgs.config.allowUnfree = true;
        imports = [
          inputs.sops-nix.nixosModules.sops
          (mylib.relativeToRoot "hosts/nixos-agent/default.nix")
          (mylib.relativeToRoot "modules/nixos/base")
          (mylib.relativeToRoot "secrets/default.nix")
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = null;
            home-manager.extraSpecialArgs = {
              inherit inputs mylib globals;
              hostMeta = agentNode;
              userMeta = agentUserMeta;
              timeMeta = agentTimeMeta;
              editorMeta = agentEditorMeta;
            };
            home-manager.users.luck.imports =
              map mylib.relativeToRoot [
                "secrets/default.nix"
                "hosts/nixos-agent/home.nix"
                "home/core"
                "home/base/AI"
              ]
              ++ [
                inputs.nix-index-database.homeModules.default
                inputs.nvf.homeManagerModules.default
                inputs.sops-nix.homeManagerModules.sops
              ];
          }
        ];
      };
    };
  }
