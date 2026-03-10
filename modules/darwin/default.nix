# Darwin-specific modules
{
  inputs,
  mylib,
  ...
}: {
  imports =
    [
      inputs.determinate.darwinModules.default
    ]
    ++ mylib.scanPaths ./.;

  # Determinate uses its own daemon to manage the Nix installation that conflicts with nix-darwin’s native Nix management. To turn off nix-darwin’s management of the Nix installation.
  nix.enable = false;

  # 启用 Determinate Nix module，确保 nix.custom.conf / daemon 路径按官方方式管理。
  determinateNix.enable = true;
}
