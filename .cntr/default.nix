{inputs, ...}: let
  nmdcModule = builtins.scopedImport {
    projectName = "\${projectName}";
    dbPassword = "\${dbPassword}";
  } (inputs.nix-managed-docker-compose + "/module.nix");
in {
  imports = [
    nmdcModule
    ./services.nix
  ];
}
