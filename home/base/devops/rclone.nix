{
  pkgs,
  config,
  ...
}:
let
  # rclone.conf 是 INI，用 formats.ini，不用 programs.rclone.remotes（后者走 systemd/launchd 运行时写 mutable 文件，不进 home-manager-files，Darwin 上 还曾长期不落地；与本仓库「home.file 真纳管」惯例不一致）。
  iniFormat = pkgs.formats.ini { };
in
{
  home = {
    packages = [ pkgs.rclone ];

    # 配置路径: ~/.config/rclone/rclone.conf
    # force：盖掉旧 launchd/手工留下的明文 conf，避免双轨。
    # ⚠️  不把 AK/SK 写进 conf（会进 store）。密钥见下方 sessionVariables + env_auth。
    # ⚠️  接受不 interactive：`rclone config` 会因 conf 为 store 软链而失败——改 remote 只改本文件。
    file.".config/rclone/rclone.conf" = {
      force = true;
      source = iniFormat.generate "rclone.conf" {
        r2 = {
          type = "s3";
          provider = "Cloudflare";
          # 运行时从环境读凭证（见 sessionVariables 的 AWS_*）；不把 secret 写进 conf/store。
          env_auth = true;
          region = "auto";
          endpoint = "https://96540bd100b82adba941163704660c31.r2.cloudflarestorage.com";
          acl = "private";
        };

        # oss = {
        #   type = "...";
        # };
      };
    };

    # rclone s3 的 env_auth 认的是 AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY，
    # 不是 cf.nix 里的短名 CF_R2_*（那些留给手工脚本）。同一 sops 源。
    sessionVariables = {
      AWS_ACCESS_KEY_ID = "$(cat ${config.sops.secrets.CF_R2_AK.path})";
      AWS_SECRET_ACCESS_KEY = "$(cat ${config.sops.secrets.CF_R2_SK.path})";
    };
  };
}
