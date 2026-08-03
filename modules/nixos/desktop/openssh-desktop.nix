{
  lib,
  ...
}:
{
  services.openssh.settings = {
    # 桌面/跳板：开放便捷功能
    # mkForce：kernel/openssh.nix 基线上默认 X11Forwarding=false（服务器安全基线），
    # desktop 语义是在其之上放开，需显式覆盖优先级。
    X11Forwarding = lib.mkForce true;
  };
}
