{
  config,
  myvars,
  pkgs,
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
      # Rclone R2 secrets
      "rclone/r2/access_key_id" = {
        owner = myvars.username;
        group = platform.userGroup;
        mode = "0400";
      };
      "rclone/r2/secret_access_key" = {
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

      # zAI API secrets
      "claude/zai/token" = {
        owner = myvars.username;
        group = platform.userGroup;
        mode = "0400";
      };

      # Sing-box subscription URL
      "singbox/url" = {
        owner = "root";
        group = "root";
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
    "sk/rclone/r2/access_key_id" = {
      source = config.sops.secrets."rclone/r2/access_key_id".path;
    };
    "sk/rclone/r2/secret_access_key" = {
      source = config.sops.secrets."rclone/r2/secret_access_key".path;
    };
    "sk/ssh/github/private_key" = {
      source = config.sops.secrets."ssh/github/private_key".path;
    };
    "sk/ssh/vps/private_key" = {
      source = config.sops.secrets."ssh/vps/private_key".path;
    };
    "sk/claude/zai/token" = {
      source = config.sops.secrets."claude/zai/token".path;
    };
    "sk/singbox/url" = {
      source = config.sops.secrets."singbox/url".path;
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

    if [ -f ${skBasePath}/rclone/r2/access_key_id ]; then
      chown ${myvars.username}:${platform.userGroup} ${skBasePath}/rclone/r2/access_key_id
      chmod 600 ${skBasePath}/rclone/r2/access_key_id
    fi
    if [ -f ${skBasePath}/rclone/r2/secret_access_key ]; then
      chown ${myvars.username}:${platform.userGroup} ${skBasePath}/rclone/r2/secret_access_key
      chmod 600 ${skBasePath}/rclone/r2/secret_access_key
    fi
    if [ -f ${skBasePath}/ssh/github/private_key ]; then
      chown ${myvars.username}:${platform.userGroup} ${skBasePath}/ssh/github/private_key
      chmod 600 ${skBasePath}/ssh/github/private_key
    fi
    if [ -f ${skBasePath}/ssh/vps/private_key ]; then
      chown ${myvars.username}:${platform.userGroup} ${skBasePath}/ssh/vps/private_key
      chmod 600 ${skBasePath}/ssh/vps/private_key
    fi
    if [ -f ${skBasePath}/claude/zai/token ]; then
      chown ${myvars.username}:${platform.userGroup} ${skBasePath}/claude/zai/token
      chmod 600 ${skBasePath}/claude/zai/token
    fi
    if [ -f ${skBasePath}/singbox/url ]; then
      chown root:root ${skBasePath}/singbox/url
      chmod 400 ${skBasePath}/singbox/url
    fi
  '';
}
