{...}: {
  services.openssh.settings = {
    # 桌面/跳板：开放便捷功能
    X11Forwarding = true;
  };
}
