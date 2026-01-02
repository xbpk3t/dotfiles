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
    rootGroup =
      if pkgs.stdenv.isDarwin
      then "wheel"
      else "root";
    homePath =
      if pkgs.stdenv.isDarwin
      then "/Users"
      else "/home";
  };

  # $HOME/.config/sops-nix/secrets/
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
      group = platform.rootGroup;
    };
in {
  # https://github.com/Guno327/nixcfg/tree/main/secrets sops相关配置参考该repo

  # Enable sops
  sops = {
    defaultSopsFile = ./secrets.yaml;

    # darwin和linux对于sops的默认path不同
    # failed to create reader for decrypting sops data key with age: no identity matched any of the recipients. Did not find keys in locations 'SOPS_AGE_SSH_PRIVATE_KEY_FILE','/Users/luck/.ssh/id_rsa', 'SOPS_AGE_KEY','SOPS_AGE_KEY_FILE', and 'SOPS_AGE_KEY_CMD'.
    age.keyFile =
      if pkgs.stdenv.isDarwin
      then "${platform.homePath}/${myvars.username}/Library/Application Support/sops/age/keys.txt"
      else "${platform.homePath}/${myvars.username}/.config/sops/age/keys.txt";

    age.sshKeyPaths = []; # Disable SSH key import
    gnupg.home = null; # Disable GPG key import

    # Define secrets
    secrets = {
      meMobile = mkUserSecret "me/mobile";
      mePass = mkUserSecret "me/pass";

      mail = mkUserSecret "me/mail";
      mailGoogle = mkUserSecret "me/mail_google";
      mailMe = mkUserSecret "me/mail_me";

      pwgenSk = mkUserSecret "pwgen/sk";

      # Rclone R2 secrets
      rcloneR2AccessKeyId = mkUserSecret "rclone/r2/access_key_id";
      rcloneR2SecretAccessKey = mkUserSecret "rclone/r2/secret_access_key";

      # SSH secrets
      sshGithubPrivateKey = mkUserSecret "ssh/github";
      sshHKClawPrivateKey = mkUserSecret "ssh/hk-claw";
      sshHKPrivateKey = mkUserSecret "ssh/hk-hdy";
      sshLAPrivateKey = mkUserSecret "ssh/la-rn";

      # zAI API secrets
      claudeZaiToken = mkUserSecret "claude/zai/token";

      # Sing-box subscription URL
      singboxUrl = mkRootSecret "singbox/url";
      singboxToken = mkRootSecret "singbox/token";

      # Shared API tokens
      youtubeApiKey = mkUserSecret "youtube/api_key";
      yuqueToken = mkUserSecret "yuque/token";
      githubAccessToken = mkUserSecret "github/access_token";
      pixivRefreshToken = mkUserSecret "pixiv/refresh_token";
      spotifyClientId = mkUserSecret "spotify/client_id";
      spotifyClientSecret = mkUserSecret "spotify/client_secret";

      # Atuin
      autinKey = mkUserSecret "atuin/key";
      autinSession = mkUserSecret "atuin/session";
    };
  };
}
