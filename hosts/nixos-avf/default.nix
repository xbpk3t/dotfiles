{userMeta, ...}: let
  hostName = "nixos-avf";
in {
  # why this? 把Android手机作为个人项目的开发机remote server使用

  networking.hostName = hostName;

  # 关键：AVF 运行环境通常是 Android Terminal VM，目标架构应显式固定为 aarch64-linux。
  # 这样可以避免后续在非 arm64 主机上评估/构建时，把 hostPlatform 误解成当前宿主机。
  nixpkgs.hostPlatform = "aarch64-linux";

  avf = {
    # 关键：Android Terminal 首次进入时会直接使用这个用户登录。
    # 这里复用仓库里的主用户名，避免再引入一套单独命名。
    defaultUser = userMeta.username;

    # 说明：先保持 graphics 打开，符合 upstream 默认行为。
    # 若后续遇到特定设备兼容性问题，再按机型关闭。
    enableGraphics = true;
  };

  # 说明：这是全新 profile，直接使用当前代际的 stateVersion。
  # stateVersion 影响 stateful data migration，后续不要随意改动。
  system.stateVersion = "25.11";
}
