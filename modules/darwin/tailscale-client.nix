_: {
  # https://mynixos.com/nix-darwin/options/services.tailscale

  # Warning: client version "1.96.5" != tailscaled server version "1.96.5-t4ee448d3a-g74ffbefc2"
  # 会出现这个 warning, 大概率并非版本真不一致，或者版本漂移问题，应该是 server version本身格式不对
  services.tailscale = {
    enable = true;
    # https://mynixos.com/nix-darwin/option/services.tailscale.overrideLocalDns
    # 启用后，设备会忽略本地 DNS 设置，改为始终使用 tailnet 里定义的全局 nameserver。这个机制适合几种场景：你要稳定解析私有 DNS 记录、你不想信任当前 Wi-Fi/局域网给你的 DNS、或者你希望所有 DNS 都强制走 NextDNS / Control D / 自建解析器。
    # 但它也有明显副作用：因为它把 100.100.100.100 设成 sole DNS，所以如果你没有在 Tailscale 后台配好至少一个可用的 DNS server，或者控制面板里没把对应开关开对，非 MagicDNS 查询会直接失败。所以如果你只是普通用 Tailscale 联网，不依赖 MagicDNS / 全局 nameserver / 分流 DNS，这个选项通常没必要开。
    # overrideLocalDns = true;
  };
}
