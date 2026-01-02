{pkgs, ...}: {
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/nixos-anywhere
    # 因为可能之后也会用mac作为核心控制端，所以直接放到base里，来多端复用（而非放到专门nixos的nix文件里）
    # 之所以放在这里，因为无论是nixos还是mac都会引入 home/base/desktop，严格对应关系引用
    nixos-anywhere

    # 同上，同样只有workstation才有必要引入colmena
    colmena
  ];

  modules.ssh = {
    enable = true;
    hosts = {
      # github.enable = true;
      hk-claw.enable = true;
      hk-hdy.enable = true;
      LA.enable = true;
    };
  };
}
