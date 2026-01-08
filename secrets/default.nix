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

    secrets = {
      # Me
      me_pwgen = mkUserSecret "me/pwgen";

      # Cloudflare
      # cf_account = mkUserSecret "cloudflare/account_id";
      # cfTokenDNS = mkUserSecret "cloudflare/token/DNS";
      cf_r2_AK = mkUserSecret "cloudflare/r2/ak";
      cf_r2_SK = mkUserSecret "cloudflare/r2/sk";

      # SSH
      ssh_github = mkUserSecret "ssh/github";
      ssh_clawcloud = mkUserSecret "ssh/claw";
      ssh_hdy = mkUserSecret "ssh/hdy";
      ssh_racknerd = mkUserSecret "ssh/RN";

      # LLM
      LLM_GLM = mkUserSecret "LLM/GLM";
      LLM_deepseek = mkUserSecret "LLM/deepseek";

      # singbox
      singbox_UUID = mkRootSecret "singbox/UUID";
      singbox_pri_key = mkRootSecret "singbox/pri_key";
      singbox_pub_key = mkRootSecret "singbox/pub_key";
      singbox_ID = mkRootSecret "singbox/id";
      singbox_hy2_pwd = mkRootSecret "singbox/hy2_pwd";
      singbox_flyingbird = mkRootSecret "singbox/flyingbird";

      # Shared API tokens
      #      youtubeApiKey = mkUserSecret "youtube/api_key";
      #      yuqueToken = mkUserSecret "yuque/token";
      #      githubAccessToken = mkUserSecret "github/access_token";
      #      pixivRefreshToken = mkUserSecret "pixiv/refresh_token";
      #      spotifyClientId = mkUserSecret "spotify/client_id";
      #      spotifyClientSecret = mkUserSecret "spotify/client_secret";

      # Atuin
      autin_key = mkUserSecret "atuin/key";
      autin_session = mkUserSecret "atuin/session";

      # Acme
      acme_cloudflare_env = mkUserSecret "acme/cloudflare_env";
    };
  };
}
