{pkgs, ...}: {
  # FIXME 玩下 nix + TF

  # https://mynixos.com/nixpkgs/packages/terraform-providers
  # https://github.com/terranix/terranix

  # https://registry.terraform.io/providers/ubiquiti-community/unifi/latest/docs
  # https://github.com/paultyng/terraform-provider-unifi
  home.packages = with pkgs; [
    # CICD
    # ansible  # Temporarily disabled due to hash mismatch in ncclient dependency
    opentofu
    cf-terraforming
  ];
}
