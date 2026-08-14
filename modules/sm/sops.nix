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
{
  inputs,
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

  imports = [
    # sops-nix 的 NixOS 模块（非我们 modules/nixos/**；sm 官方测试证明可用）
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
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
    };
  };

  # sops-install-secrets 挂在 sysinit-reactivation.target 前触发（sm 引擎启动它）。
  # 注意：不设 sops.environment（避免与 sm systemd PATH 冲突；默认 PATH 够用）。
  systemd.services.sops-install-secrets = {
    before = [ "sysinit-reactivation.target" ];
    requiredBy = [ "sysinit-reactivation.target" ];
  };
}
