{...}: {
  services.openssh.settings = {
    # VPS 不提供图形，关闭 X11 转发
    X11Forwarding = false;

    # 服务器场景：保持最小信任域，关闭 GSSAPI/SASL 等域认证通道
    # 禁用键盘交互（含 OTP/PAM），减少暴力破解面
    KbdInteractiveAuthentication = false;

    # 禁止代理转发，避免泄露本地凭据
    AllowAgentForwarding = false;
  };
}
