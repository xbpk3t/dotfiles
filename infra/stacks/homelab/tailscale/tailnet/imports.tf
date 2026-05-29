# 三个资源的 import 方式各不相同：
#
# 1. tailscale_acl — 单例资源，import ID 用任意字符串即可（如 "acl"）
#    计划原以为"不需要显式 import，会自动读取 live state"，实测并非如此，
#    仍需显式 import，只是 ID 不敏感。
#    tofu import tailscale_acl.main acl
#
# 2. tailscale_dns_preferences — 同样是单例，ID 任意字符串（如 "dns_preferences"）
#    tofu import tailscale_dns_preferences.main dns_preferences
#
# 3. tailscale_tailnet_key — 非单例，必须用 key 的数字 ID，不是 tskey-auth-xxx 字串
#    key ID 通过 API 获取：
#    curl -u ":$TAILSCALE_API_KEY" https://api.tailscale.com/api/v2/tailnet/xbpk3t.github/keys
#    tofu import tailscale_tailnet_key.device_join <key-id>
