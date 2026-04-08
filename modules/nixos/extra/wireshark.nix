{
  config,
  lib,
  userMeta,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.extra.wireshark;
  username = userMeta.username;
in {
  options.modules.extra.wireshark = {
    enable = mkEnableOption "Wireshark capture capability on NixOS";
  };

  # 1. wireshark 本身同时支持 nixos/darwin，为啥把wireshark的 NixOS 和 darwin 拆成两部分（darwin的 wireshark 由 brew 安装）？
  ## 因为 darwin的 wireshark-app 本身就配置了 BPF权限、dumpcap, usbmon 等配置项，可以直接使用（而我们实际上无法直接在nix里直接对darwin做出上述配置，或过于复杂，遂无必要），而 nixos 上则可以直接使用本文件直接使用.
  ## nixpkgs 本身支持 darwin，但当前仓库在 darwin 侧优先用 brew cask 处理 app + BPF 权限.

  # 2. 为啥把 wireshark 相关配置拆分到 modules/home 两部分？而非都放到 home 或者 modules 里？
  ## 原因是显而易见的，不多说明。（抓包权限、wireshark 组、dumpcap wrapper 属于 NixOS system layer，因此保留在这里。）
  config = mkIf cfg.enable {
    # https://mynixos.com/nixpkgs/options/programs.wireshark
    # https://mynixos.com/nixpkgs/package/wireshark
    programs.wireshark = {
      enable = true;
      # Whether to allow users in the 'wireshark' group to capture network traffic(via a setcap wrapper).
      dumpcap.enable = true;
      # Whether to allow users in the 'wireshark' group to capture USB traffic (via udev rules).
      usbmon.enable = false;
    };

    users.groups = {wireshark = {};};
    users.users."${username}".extraGroups = ["wireshark"];
  };
}
