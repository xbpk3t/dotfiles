{
  inputs,
  lib,
  mylib,
  userMeta,
  globals,
  hostMeta,
  timeMeta,
  editorMeta,
  pkgs,
  ...
}:
let
  agentNodes = mylib.inventory.nodesForContainerHost "nixos-agent" hostMeta.hostName;
  agentNode = agentNodes.nixos-agent or null;
  agentEnabled = agentNode != null;
  agentUserMeta = agentNode.user or userMeta;
  agentTimeMeta = agentNode.time or timeMeta;
  agentEditorMeta = agentNode.editor or editorMeta;
  agentStateVersion = agentNode.stateVersion or "24.11";
in
lib.mkIf agentEnabled {
  containers.nixos-agent = {
    autoStart = agentNode.autoStart or true;
    privateNetwork = true;
    hostAddress = "10.233.0.1";
    localAddress = agentNode.primaryIp or "10.233.0.2";
    specialArgs = {
      inherit inputs mylib globals;
      hostMeta = agentNode;
      userMeta = agentUserMeta;
      timeMeta = agentTimeMeta;
      editorMeta = agentEditorMeta;
      stateVersion = agentStateVersion;
    };
    config = {
      # 容器使用宿主机（nixos-vps）的 pkgs → nixpkgs-stable
      # allowUnfree + overlay 已由宿主机 pkgs 内置，不设 config/overlays 避免断言冲突
      nixpkgs.pkgs = pkgs;
      imports = [
        inputs.sops-nix.nixosModules.sops
        (mylib.relativeToRoot "hosts/nixos-agent/default.nix")
        (mylib.relativeToRoot "modules/nixos/base")
        (mylib.relativeToRoot "secrets/default.nix")
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = null;
            extraSpecialArgs = {
              inherit inputs mylib globals;
              hostMeta = agentNode;
              userMeta = agentUserMeta;
              timeMeta = agentTimeMeta;
              editorMeta = agentEditorMeta;
              stateVersion = agentStateVersion;
            };
            users.luck.imports =
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
          };
        }
      ];
    };
  };
}
