let
  # 统一维护可用 cache 列表（仅保留有对应 public key 的源）。
  substituters = [
    "https://cache.nixos.org"
    "https://cache.garnix.io"
    "https://nix-community.cachix.org"
    "https://watersucks.cachix.org"
    "https://cache.numtide.com"
  ];

  # 与 substituters 一一对应的 trusted public keys。
  trustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "watersucks.cachix.org-1:6gadPC5R8iLWQ3EUtfu3GFrVY7X6I4Fwz/ihW25Jbv8="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];
in {
  inherit substituters trustedPublicKeys;

  # 预渲染成 nix.conf 需要的空格分隔格式，避免在业务模块重复拼接字符串。
  asNixConf = {
    substituters = builtins.concatStringsSep " " substituters;
    trustedPublicKeys = builtins.concatStringsSep " " trustedPublicKeys;
  };
}
