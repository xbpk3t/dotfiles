# Tailscale 角色约定：role → 设备 tag + 加入 key（sops secret 名/路径）。
#
# NixOS / Darwin 模块与 terranix 共用这一份映射，避免 key 名、tag 名在多处漂移。
# 角色是 hostMeta.tailscale.role 的值；未知角色直接报错，不静默落到某个默认值
# （否则 typo 会让设备拿错角色的加入 key）。
{ lib }:
let
  roles = {
    ws = {
      tag = "tag:ws";
      secretName = "TAILSCALE_AUTH_KEY_WS";
      secretPath = "tailscale/auth_key_ws";
    };
    vps = {
      tag = "tag:vps";
      secretName = "TAILSCALE_AUTH_KEY_VPS";
      secretPath = "tailscale/auth_key_vps";
    };
  };

  roleInfo =
    role:
    roles.${role}
      or (throw "tailscale: unknown role '${role}' (expected: ${lib.concatStringsSep " | " (lib.attrNames roles)})");
in
{
  inherit roles roleInfo;
}
