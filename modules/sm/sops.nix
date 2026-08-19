# sm 轨系统 sops（root secrets）。
# 机制（Phase 8 查证）：sm 官方自 PR #270 起支持系统 sops——
# sops-nix 的 `nixosModules.sops` 在 sm 下通过 `systemd.services.sops-install-secrets`
# 触发解密（不是 activation script），sm 引擎能启动 systemd service。
#
# 为什么不 import secrets/default.nix：
#   secrets/default.nix 含 macOS HM 特用的 sops.environment.PATH（/etc/profiles/per-user/luck）
#   + age.keyFile（/home/...）。sm 系统 sops 下这些会与 sm 的 systemd PATH 冲突。
#   因此这里手动声明 root secrets（复用 secrets.yaml 同一份加密文件），
#   isSystemConfig 语义由 mkRootSecret 显式保证（owner=root）。
#
# 这是 sm-vps 基线能力（secrets 注入是其他服务的依赖），不做配置化开关。
# 共享机（shared=true）：系统 sops 整个关闭，不放主 age key 到 /etc/sops/age。
# 原因：keys.txt 是 secrets.yaml 全量解密钥匙；共享机上他人有 root 密码，
#       cat 一下就是全量泄露。共享机如需 secret，走 HM 专用 key + 独立小文件。
{
  inputs,
  lib,
  isShared ? false,
  ...
}:
let
  # 与 secrets/default.nix 的 mkRootSecret 一致：系统 root secret，owner=root。
  mkRootSecret = key: {
    inherit key;
    mode = "0400";
    owner = "root";
    group = "root";
  };
in
{
  _file = ./sops.nix;

  # sops-nix 模块常驻 import：声明 sops.* options（shared 下 option 存在但无定义，
  # 服务角色模块的 config.sops.* 引用可安全求值）。配置主体仍按 !isShared 门控。
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = lib.mkIf (!isShared) {
    # 与 secrets.yaml 同一份加密文件（reuse secrets/default.nix 的 defaultSopsFile）
    defaultSopsFile = ./../../secrets/secrets.yaml;

    # age key：系统 sops 独立于 HM 用户 sops。放 /etc/sops/age/keys.txt（持久，
    # 不在 tmpfs；bootstrap 时放置）。不用 /run（重启丢失）。
    age.keyFile = "/etc/sops/age/keys.txt";
    age.generateKey = false;

    # 系统 root secrets（对应 secrets/default.nix 里所有 mkRootSecret）
    secrets = {
      # proxy（自持代理节点凭据）
      PROXY_UUID = mkRootSecret "proxy/UUID";
      PROXY_PRI_KEY = mkRootSecret "proxy/pri_key";
      PROXY_PUB_KEY = mkRootSecret "proxy/pub_key";
      PROXY_ID = mkRootSecret "proxy/id";
      PROXY_PWD = mkRootSecret "proxy/pwd";
      PROXY_FLYINGBIRD = mkRootSecret "proxy/flyingbird";
      PROXY_CLASH_SK = mkRootSecret "proxy/clash_secret";
      # sub（机场订阅）
      SUB_DOGEGG = mkRootSecret "proxy/sub/dogegg";
      SUB_DOING = mkRootSecret "proxy/sub/doing";
      SUB_IKUUU = mkRootSecret "proxy/sub/ikuuu";
      # k3s
      K3S_TOKEN = mkRootSecret "k3s/token";
      # Tailscale
      TAILSCALE_AUTH_KEY = mkRootSecret "tailscale/auth_key";
      # ACME（derper 证书 DNS-01）：CF token（复用 secrets/default.nix 的 acme/cloudflare_env）。
      # email 用 userMeta.mail（inventory），不进 sops。
      ACME_CF_ENV = mkRootSecret "acme/cloudflare_env";
    };
  };

  # sops-install-secrets 挂在 sysinit-reactivation.target 前触发（sm 引擎启动它）。
  # 注意：不设 sops.environment（避免与 sm systemd PATH 冲突；默认 PATH 够用）。
  systemd.services.sops-install-secrets = lib.mkIf (!isShared) {
    before = [ "sysinit-reactivation.target" ];
    requiredBy = [ "sysinit-reactivation.target" ];
  };
}
