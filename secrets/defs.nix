# Single source of truth for sops secret definitions and ownership helpers.
#
# secrets/default.nix (full set) and secrets/minimal.nix (restricted set)
# import this file as a plain function, so the secret-name -> secrets.yaml
# key mapping and the root/user ownership rules are defined exactly once.
{
  config,
  lib,
  pkgs,
  userMeta,
}:
let
  isSystemConfig = config ? system;
  # neededForUsers 只属于 sops-nix 的 NixOS 模块；nix-darwin 不认这个选项。
  isNixOS = isSystemConfig && pkgs.stdenv.hostPlatform.isLinux;
  inherit (userMeta) username;
  # 平台相关配置
  platform = {
    userGroup = if pkgs.stdenv.hostPlatform.isDarwin then "staff" else "users";
    rootGroup = if pkgs.stdenv.hostPlatform.isDarwin then "wheel" else "root";
    homePath = if pkgs.stdenv.hostPlatform.isDarwin then "/Users" else "/home";
  };

  # $HOME/.config/sops-nix/secrets/
  mkUserSecret =
    key:
    {
      inherit key;
      mode = "0400";
    }
    // lib.optionalAttrs isSystemConfig {
      owner = username;
      group = platform.userGroup;
    };

  mkRootSecret =
    key:
    {
      inherit key;
      mode = "0400";
    }
    // lib.optionalAttrs isSystemConfig {
      owner = "root";
      group = platform.rootGroup;
    };
in
{
  inherit platform mkUserSecret mkRootSecret;

  secrets = {
    # Me
    ME_PASS = mkUserSecret "me/pass";
    # NixOS 用户密码 hash（root + luck），由 hashedPasswordFile 消费。
    # neededForUsers 要求 owner=root，且必须在建用户前解密。
    ME_PASS_HASH =
      (mkRootSecret "me/pass_hash") // lib.optionalAttrs isNixOS { neededForUsers = true; };
    ME_PWGEN = mkUserSecret "me/pwgen";
    ME_SK = mkUserSecret "me/sk";

    # Cloudflare
    CF_ACCOUNT = mkUserSecret "cf/account_id";
    CF_ZONE = mkUserSecret "cf/zone_id";

    CF_R2_AK = mkUserSecret "cf/r2/ak";
    CF_R2_SK = mkUserSecret "cf/r2/sk";
    CF_R2_ENDPOINT = mkUserSecret "cf/r2/endpoint";

    # 全能 Cloudflare token（read/write），供 Terraform / 日常 API 使用。
    CLOUDFLARE_API_TOKEN = mkUserSecret "cf/token/all";

    # SSH
    SSH_GITHUB = mkUserSecret "ssh/github";

    # LLM
    LLM_AxonHub = mkUserSecret "LLM/AxonHub";
    LLM_ANY_TOKEN = mkUserSecret "LLM/AnyRouter";

    # proxy（自持代理节点凭据，singbox server + mihomo self provider 共用）
    PROXY_UUID = mkRootSecret "proxy/UUID";
    PROXY_PRI_KEY = mkRootSecret "proxy/pri_key";
    PROXY_PUB_KEY = mkRootSecret "proxy/pub_key";
    PROXY_ID = mkRootSecret "proxy/id";
    PROXY_PWD = mkRootSecret "proxy/pwd";
    PROXY_FLYINGBIRD = mkRootSecret "proxy/flyingbird";
    PROXY_CLASH_SK = mkRootSecret "proxy/clash_secret";

    # sub（机场订阅，挂在 proxy 下）：key = 源名，value = 订阅 URL（含 token）。
    # 新增机场 = 这里加一条 SUB_<NAME> + secrets.yaml 加 proxy.sub.<name>，mihomo 自动发现。
    SUB_IKUUU = mkRootSecret "proxy/sub/ikuuu";
    SUB_9TI = mkRootSecret "proxy/sub/9ti";

    # Shared API tokens
    # youtubeApiKey = mkUserSecret "youtube/api_key";
    # yuqueToken = mkUserSecret "yuque/token";
    # pixivRefreshToken = mkUserSecret "pixiv/refresh_token";
    # spotifyClientId = mkUserSecret "spotify/client_id";
    # spotifyClientSecret = mkUserSecret "spotify/client_secret";

    RESEND_TOKEN = mkUserSecret "resend/pwd";

    # Backup（restic 仓库密码；恢复到任何机器都需要它）
    RESTIC_PASSWORD = mkUserSecret "restic/password";

    API_CONTEXT7 = mkUserSecret "API/context7";
    API_LINEAR = mkUserSecret "API/linear";
    GITHUB_TOKEN = mkUserSecret "API/github";
    DOCKER_HUB_TOKEN = mkUserSecret "API/docker_hub";
    API_TAVILY = mkUserSecret "API/tavily";
    API_EXA = mkUserSecret "API/exa";
    API_KEENABLE = mkUserSecret "API/keenable";
    API_TMDB = mkUserSecret "API/tmdb";
    FEISHU_APP_SECRET = mkUserSecret "API/feishu";

    GOOGLE_CLOUD_API_KEY = mkUserSecret "google/cloud";

    # Atuin
    # 登录态在 ~/.local/share/atuin/meta.db (hub_session/session)，不通过 sops 注入；
    # 旧的 atuin/session token 已失效，各机手动 `atuin login` 一次。
    # 详见 home/core/kernel/zsh.nix 的 NOTE(atuin)。
    AUTIN_KEY = mkUserSecret "atuin/key";

    # Acme
    ACME_CF_ENV = mkUserSecret "acme/cloudflare_env";

    # Tailscale auth key 按角色声明，避免每台机器都解密两条：
    # - NixOS：modules/nixos/infra/tailscale-client.nix
    # - Darwin：modules/darwin/networking/tailscale-client.nix
    # - sm：modules/sm/sops.nix
    TAILSCALE_API_KEY = mkUserSecret "tailscale/access_key";

    # Nezha monitoring
    # Dashboard JWT signing key; agent SK shared by hub and every agent.
    # Both are read by systemd LoadCredential (root-only).
    NEZHA_JWT_SK = mkRootSecret "nezha/jwt_sk";
    NEZHA_AGENT_SK = mkRootSecret "nezha/agent_sk";

    # Healthchecks.io dead-man switches
    HEALTHCHECKS_VPS_DEV = mkRootSecret "healthchecks/vps_dev";
    HEALTHCHECKS_VPS_AGT = mkRootSecret "healthchecks/vps_agt";
  };
}
