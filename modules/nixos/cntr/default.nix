{
  inputs,
  mylib,
  ...
}: let
  nmdcModule = builtins.scopedImport {
    projectName = "\${projectName}";
    dbPassword = "\${dbPassword}";
  } (inputs.nix-managed-docker-compose + "/module.nix");
  serviceModules = mylib.scanPaths ./modules;
in {
  imports =
    [
      nmdcModule
      ./reverse-proxy.nix
    ]
    ++ serviceModules;
}
