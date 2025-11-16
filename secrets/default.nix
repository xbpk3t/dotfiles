{
  config,
  myvars,
  pkgs,
  lib,
  ...
}: let
  isSystemConfig = config ? system;
  # 平台相关配置
  platform = {
    userGroup =
      if pkgs.stdenv.isDarwin
      then "staff"
      else "users";
    homePath =
      if pkgs.stdenv.isDarwin
      then "/Users"
      else "/home";
  };

  mkUserSecret = key:
    {
      inherit key;
      mode = "0400";
    }
    // lib.optionalAttrs isSystemConfig {
      owner = myvars.username;
      group = platform.userGroup;
    };

  mkRootSecret = key:
    {
      inherit key;
      mode = "0400";
    }
    // lib.optionalAttrs isSystemConfig {
      owner = "root";
      group = "root";
    };
in {
  # https://github.com/Guno327/nixcfg/tree/main/secrets sops相关配置参考该repo

  # Enable sops
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "${platform.homePath}/${myvars.username}/.config/sops/age/keys.txt";
    age.sshKeyPaths = []; # Disable SSH key import
    gnupg.home = null; # Disable GPG key import

    # Define secrets
    secrets = {
      meMobile = mkUserSecret "me/mobile";
      mePass = mkUserSecret "me/pass";
      pwgenSk = mkUserSecret "pwgen/sk";
      # Rclone R2 secrets
      rcloneR2AccessKeyId = mkUserSecret "rclone/r2/access_key_id";
      rcloneR2SecretAccessKey = mkUserSecret "rclone/r2/secret_access_key";

      # SSH secrets
      sshGithubPrivateKey = mkUserSecret "ssh/github/private_key";
      sshVpsPrivateKey = mkUserSecret "ssh/vps/private_key";

      # zAI API secrets
      claudeZaiToken = mkUserSecret "claude/zai/token";

      # Sing-box subscription URL
      singboxUrl = mkRootSecret "singbox/url";
    };
  };
}
