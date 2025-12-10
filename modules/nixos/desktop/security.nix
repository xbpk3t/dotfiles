{pkgs, ...}: {
  # https://mynixos.com/nixpkgs/options/security.apparmor
  # PLAN AppArmor

  # https://mynixos.com/nixpkgs/package/bubblewrap

  # seahorse is a GUI App for GNOME Keyring.
  programs.seahorse.enable = true;
  # The OpenSSH agent remembers private keys for you
  # so that you don’t have to type in passphrases every time you make an SSH connection.
  # Use `ssh-add` to add a key to the agent.
  programs.ssh.startAgent = true;

  # gpg agent with pinentry
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
    enableSSHSupport = false;
    settings.default-cache-ttl = 4 * 60 * 60; # 4 hours
  };
}
