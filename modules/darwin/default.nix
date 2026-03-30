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

  determinateNix.determinateNixd = {
    garbageCollector = {
      # 显式固定 Darwin 侧的 GC owner 为 Determinate Nixd。
      # why:
      # 1. 当前 Darwin 已经关闭 nix-darwin 自身的 Nix 管理（nix.enable = false）
      # 2. GC policy 如果只依赖上游 default，后续升级时语义可能漂移
      # 3. 在仓库里写明 strategy，后续排查时能直接从 config 看出 owner
      strategy = "automatic";
    };
  };
}
