{
  config,
  username,
  ...
}:

{
  # Enable sops
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/Users/${username}/Desktop/dotfiles/nix/secrets/age.key";

    # Define secrets
    secrets = {
      # Rclone R2 secrets
      "rclone/r2/access_key_id" = {
        owner = username;
        group = "staff";
        mode = "0400";
      };
      "rclone/r2/secret_access_key" = {
        owner = username;
        group = "staff";
        mode = "0400";
      };

      # SSH secrets
      "ssh/github/private_key" = {
        owner = username;
        group = "staff";
        mode = "0400";
      };
    };
  };

  # Place secrets in /etc/ for easy access
  environment.etc = {
    "rclone/r2/access_key_id" = {
      source = config.sops.secrets."rclone/r2/access_key_id".path;
    };
    "rclone/r2/secret_access_key" = {
      source = config.sops.secrets."rclone/r2/secret_access_key".path;
    };
    "ssh/github/private_key" = {
      source = config.sops.secrets."ssh/github/private_key".path;
    };
  };

  # Set proper permissions for the secrets
  system.activationScripts.postActivation.text = ''
    if [ -f /etc/rclone/r2/access_key_id ]; then
      chown ${username}:staff /etc/rclone/r2/access_key_id
      chmod 600 /etc/rclone/r2/access_key_id
    fi
    if [ -f /etc/rclone/r2/secret_access_key ]; then
      chown ${username}:staff /etc/rclone/r2/secret_access_key
      chmod 600 /etc/rclone/r2/secret_access_key
    fi
    if [ -f /etc/ssh/github/private_key ]; then
      chown ${username}:staff /etc/ssh/github/private_key
      chmod 600 /etc/ssh/github/private_key
    fi
  '';
}
