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

    # [2026-01-24]
    # context: 把dotfiles从homelab迁回mac之后，发现secrets无法在本地生成到 $HOME/.config/sops-nix/secrets. 导致所有服务都挂掉了。
    #
    # 关键问题是 sops‑nix 的 Home Manager 模块在 macOS 用 LaunchAgent，EnvironmentVariables 来自 sops.environment，而 PATH 被模块默认写成空字符串；因此 getconf 找不到，导致运行目录创建失败，进而只生成极少文件。这和你从 remote 切回本地、 LaunchAgent 被重建后 PATH 为空的现象一致。Home Manager 的 launchd 配置项确实是 launchd.agents.<name>.config，对应到 plist 的键值。
    #
    # 注意这里 lib.mkForce，因为如果不mkForce 仍然会按照默认 空字符串 赋值，导致该配置无效
    #
    # 让 sops-install-secrets 的 LaunchAgent 拿到可用 PATH（需要 getconf）
    environment.PATH = lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin:/run/current-system/sw/bin:/etc/profiles/per-user/${myvars.username}/bin";

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
      singbox_clash_secret = mkRootSecret "singbox/clash_secret";

      # Shared API tokens
      # youtubeApiKey = mkUserSecret "youtube/api_key";
      # yuqueToken = mkUserSecret "yuque/token";
      # githubAccessToken = mkUserSecret "github/access_token";
      # pixivRefreshToken = mkUserSecret "pixiv/refresh_token";
      # spotifyClientId = mkUserSecret "spotify/client_id";
      # spotifyClientSecret = mkUserSecret "spotify/client_secret";

      API_context7 = mkUserSecret "API/context7";

      # Atuin
      autin_key = mkUserSecret "atuin/key";
      autin_session = mkUserSecret "atuin/session";

      # Acme
      acme_cloudflare_env = mkUserSecret "acme/cloudflare_env";

      # k3s
      k3s_token = mkRootSecret "k3s/token";
    };
  };
}
