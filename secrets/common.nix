# Shared sops wiring for every host.
#
# The secret *sets* live in secrets/default.nix (full) and
# secrets/minimal.nix (disk/RAM-constrained VPS). Nodes import exactly one
# of them, so a public proxy never declares the full fleet set.
{
  config,
  lib,
  pkgs,
  userMeta,
  ...
}:
let
  defs = import ./defs.nix {
    inherit
      config
      lib
      pkgs
      userMeta
      ;
  };
  inherit (defs.platform) homePath;
  inherit (userMeta) username;
in
{
  sops = {
    defaultSopsFile = ./secrets.yaml;

    # darwin和linux对于sops的默认path不同
    # failed to create reader for decrypting sops data key with age: no identity matched any of the recipients. Did not find keys in locations 'SOPS_AGE_SSH_PRIVATE_KEY_FILE','/Users/luck/.ssh/id_rsa', 'SOPS_AGE_KEY','SOPS_AGE_KEY_FILE', and 'SOPS_AGE_KEY_CMD'.
    age.keyFile =
      if pkgs.stdenv.hostPlatform.isDarwin then
        "${homePath}/${username}/Library/Application Support/sops/age/keys.txt"
      else
        "${homePath}/${username}/.config/sops/age/keys.txt";

    age.sshKeyPaths = [ ]; # Disable SSH key import
    gnupg.home = null;

    # [2026-01-24]
    # context: 把dotfiles从homelab迁回mac之后，发现secrets无法在本地生成到 $HOME/.config/sops-nix/secrets. 导致所有服务都挂掉了。
    #
    # 关键问题是 sops‑nix 的 Home Manager 模块在 macOS 用 LaunchAgent，EnvironmentVariables 来自 sops.environment，而 PATH 被模块默认写成空字符串；因此 getconf 找不到，导致运行目录创建失败，进而只生成极少文件。这和你从 remote 切回本地、 LaunchAgent 被重建后 PATH 为空的现象一致。Home Manager 的 launchd 配置项确实是 launchd.agents.<name>.config，对应到 plist 的键值。
    #
    # 注意这里 lib.mkForce，因为如果不mkForce 仍然会按照默认 空字符串 赋值，导致该配置无效
    #
    # 让 sops-install-secrets 的 LaunchAgent 拿到可用 PATH（需要 getconf）
    environment.PATH = lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin:/run/current-system/sw/bin:/etc/profiles/per-user/${username}/bin";
  };
}
