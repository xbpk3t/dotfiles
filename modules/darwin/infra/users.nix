# Darwin user configuration
# Contains user configuration that can be shared between multiple hosts
{
  globals,
  lib,
  pkgs,
  userMeta,
  ...
}:
let
  inherit (userMeta) username;
in
{
  # Default user configuration (can be overridden by host-specific settings)
  users.users = {
    # Main user configuration with defaults
    "${username}" = {
      home = "/Users/${username}";
      description = username;
      shell = lib.mkDefault (pkgs.zsh + "/bin/zsh");
      # 注意：nix-darwin 不写 ~/.ssh/authorized_keys。它生成
      # /etc/ssh/nix_authorized_keys.d/<user>，并通过 sshd 的 AuthorizedKeysCommand 读取。
      # ~/.ssh/authorized_keys 留给临时 key，不要用 home.file 纳管（rebuild 会覆盖临时 key）。
      openssh.authorizedKeys.keys = globals.auth.sshPublicKeys;
    };

    # Note: Additional users should be created manually on macOS or via host-specific configuration
  };

  # Shell configuration - make shells available system-wide
  environment.shells = lib.mkDefault [
    (pkgs.zsh + "/bin/zsh")
    (pkgs.bash + "/bin/bash")
  ];

  environment.pathsToLink = lib.mkDefault [
    # "/share/zsh"
    # "/share/bash-completion"
    # "/share/nvim"
    # "/share/man"
  ];
}
