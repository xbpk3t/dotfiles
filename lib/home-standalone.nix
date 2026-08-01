{
  inputs,
  system,
  genSpecialArgs,
  home-modules ? [ ],
  specialArgs ? (genSpecialArgs system),
  # standalone 无 home.backupFileExtension option；激活时用
  # `home-manager switch -b <ext>` 或 HOME_MANAGER_BACKUP_EXT。
  # 参数保留供 Phase 2/5 activate 脚本/deploy profile 读取。
  backupFileExtension ? "hm.bak",
  ...
}:
let
  inherit (inputs) home-manager;
  # homeManagerConfiguration 用 pkgs 参数；不要把 pkgs 再塞进 extraSpecialArgs，
  # 否则与 HM 内部 _module.args.pkgs 冲突。
  extraSpecialArgs = builtins.removeAttrs specialArgs [ "pkgs" ];
  pkgs = specialArgs.pkgs;
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = extraSpecialArgs // {
    # 约定备份后缀（非 HM 官方 option）；CLI: home-manager switch -b hm.bak
    linuxSmBackupFileExtension = backupFileExtension;
  };
  modules = home-modules ++ [
    # 与 NixOS/Darwin 内嵌 HM 主线一致：nix-index wrapper + 预生成 database
    inputs.nix-index-database.homeModules.default
    # home/core 多处引用 config.sops.secrets.*；不挂 sops 模块则无法 eval。
    # Phase 1 只要求 eval；age key / 真 switch 属于 Phase 2–3。
    inputs.sops-nix.homeManagerModules.sops
  ];
}
