{
  config,
  myvars,
  pkgs,
  inputs,
  ...
}: let
  # 平台相关配置
  platform = {
    userGroup =
      if pkgs.stdenv.isDarwin
      then "staff"
      else "users";
    homePath =
      if pkgs.stdenv.isDarwin
      then "/Users"
      else "/home";
  };

  # 统一的 sk 基础路径
  skBasePath = "/etc/sk";
in {
  imports = [
    inputs.sops-nix.nixosModules.sops
    # inputs.sops-nix.darwinModules.sops
  ];

  # Enable sops
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "${platform.homePath}/${myvars.username}/.config/sops/age/keys.txt";
    age.sshKeyPaths = []; # Disable SSH key import
    gnupg.home = null; # Disable GPG key import

    # Define secrets
    secrets = {
      "me/mobile" = {
        owner = myvars.username;
        group = platform.userGroup;
        mode = "0400";
      };
      "me/pass" = {
        owner = myvars.username;
        group = platform.userGroup;
        mode = "0400";
      };

      "pwgen/sk" = {
        owner = myvars.username;
        group = platform.userGroup;
        mode = "0400";
      };
      # SSH secrets
      "ssh/github/private_key" = {
        owner = myvars.username;
        group = platform.userGroup;
        mode = "0400";
      };

      "ssh/vps/private_key" = {
        owner = myvars.username;
        group = platform.userGroup;
        mode = "0400";
      };
    };
  };

  # Place secrets in /etc/sk/ for unified management
  environment.etc = {
    "sk/me/mobile" = {
      source = config.sops.secrets."me/mobile".path;
    };
    "sk/me/pass" = {
      source = config.sops.secrets."me/pass".path;
    };
    "sk/pwgen/sk" = {
      source = config.sops.secrets."pwgen/sk".path;
    };
    "sk/ssh/github/private_key" = {
      source = config.sops.secrets."ssh/github/private_key".path;
    };
    "sk/ssh/vps/private_key" = {
      source = config.sops.secrets."ssh/vps/private_key".path;
    };
  };

  # Set proper permissions for the secrets
  system.activationScripts.postActivation.text = ''

    if [ -f ${skBasePath}/me/mobile ]; then
      chown ${myvars.username}:${platform.userGroup} ${skBasePath}/me/mobile
      chmod 600 ${skBasePath}/me/mobile
    fi

    if [ -f ${skBasePath}/me/pass ]; then
      chown ${myvars.username}:${platform.userGroup} ${skBasePath}/me/pass
      chmod 600 ${skBasePath}/me/pass
    fi

    if [ -f ${skBasePath}/pwgen/sk ]; then
      chown ${myvars.username}:${platform.userGroup} ${skBasePath}/pwgen/sk
      chmod 600 ${skBasePath}/pwgen/sk
    fi

    if [ -f ${skBasePath}/ssh/github/private_key ]; then
      chown ${myvars.username}:${platform.userGroup} ${skBasePath}/ssh/github/private_key
      chmod 600 ${skBasePath}/ssh/github/private_key
    fi
    if [ -f ${skBasePath}/ssh/vps/private_key ]; then
      chown ${myvars.username}:${platform.userGroup} ${skBasePath}/ssh/vps/private_key
      chmod 600 ${skBasePath}/ssh/vps/private_key
    fi
  '';
}
