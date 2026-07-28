{
  pkgs,
  config,
  ...
}:
let
  # rclone.conf 是 INI。用 sops.templates 渲染含 AK/SK 的完整配置，
  # 不走 programs.rclone.remotes（Darwin 上 launchd 弱收敛），
  # 也不走 env_auth + sessionVariables（HM guard 导致子 shell 丢失 env）。
  # 跟 mihomo/singbox 同一模式：sops 运行时注入密钥，不进 nix store。
  rcloneConfPath = config.sops.templates."rclone.conf".path;
in
{
  home = {
    packages = [ pkgs.rclone ];

    # 配置路径: ~/.config/rclone/rclone.conf
    # 用 mkOutOfStoreSymlink 指向 sops 渲染出来的路径（含 AK/SK），
    # force 盖掉旧文件。不用 source = path 是因为 eval 时 sops 路径还不存在。
    # ⚠️  接受不 interactive：`rclone config` 会因 conf 为 store 软链而失败——改 remote 只改本文件。
    file.".config/rclone/rclone.conf" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink rcloneConfPath;
    };
  };

  # sops 运行时渲染完整 conf（含 AK/SK），不进 /nix/store。
  # 渲染结果由 sops-install-secrets 写入 store 外路径，home.file 软链指向它。
  # ${config.sops.placeholder.CF_R2_AK} 是 sops placeholder，激活时被替换为实际密钥值。
  sops.templates."rclone.conf" = {
    content = ''
      [r2]
      type = s3
      provider = Cloudflare
      env_auth = false
      access_key_id = ${config.sops.placeholder.CF_R2_AK}
      secret_access_key = ${config.sops.placeholder.CF_R2_SK}
      region = auto
      endpoint = https://96540bd100b82adba941163704660c31.r2.cloudflarestorage.com
      acl = private
    '';
  };
}
