{
  config,
  pkgs,
  agenix,
  username,
  ...
}:
{

  # enable logs for debugging
  launchd.daemons."activate-agenix".serviceConfig = {
    StandardErrorPath = "/Library/Logs/org.nixos.activate-agenix.stderr.log";
    StandardOutPath = "/Library/Logs/org.nixos.activate-agenix.stdout.log";
  };

  environment.systemPackages = [
    agenix.packages."${pkgs.system}".default
  ];

  # if you changed this key, you need to regenerate all encrypt files from the decrypt contents!
  age.identityPaths = [
    # Use the age key we generated
    "/Users/${username}/Desktop/dotfiles/nix/secrets/age.key"
  ];

  age.secrets =
    let
      user_readable = {
        mode = "0400";
        owner = username;
      };
    in
    {
      # GitHub SSH private key
      "github-ssh-key" = {
        file = ./github-ssh-key.age;
      }
      // user_readable;
    };

  # place secrets in /etc/
  environment.etc = {
    "agenix/github-ssh-key" = {
      source = config.age.secrets."github-ssh-key".path;
    };
  };

  # Set proper permissions for the SSH key
  system.activationScripts.postActivation.text = ''
    if [ -f /etc/agenix/github-ssh-key ]; then
      chown ${username}:staff /etc/agenix/github-ssh-key
      chmod 600 /etc/agenix/github-ssh-key
    fi
  '';
}
