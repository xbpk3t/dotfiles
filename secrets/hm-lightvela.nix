{
  lib,
  mylib,
  userMeta,
  ...
}:
{
  # PA-only secret subset. Do not import ./default.nix: the PA is vendor-managed
  # and must not receive the full fleet secret set. Keep this list in sync with
  # the modules imported by home/hm/default.nix.
  sops = {
    defaultSopsFile = lib.mkForce (mylib.relativeToRoot "secrets/hm-lightvela.yaml");
    age.keyFile = lib.mkForce "/root/.config/sops/age/keys.txt";
    age.sshKeyPaths = [ ];
    gnupg.home = null;

    # sops-nix's Home Manager activation needs a usable PATH (getconf); without
    # this the module defaults to an empty PATH on some platforms.
    environment.PATH = lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin:/run/current-system/sw/bin:/etc/profiles/per-user/${userMeta.username}/bin";

    secrets = {
      # Used by home/core/devops/gh.nix.
      GITHUB_TOKEN = {
        key = "API/github";
        mode = "0400";
      };
      RESEND_TOKEN = {
        key = "resend/pwd";
        mode = "0400";
      };

      # Used by home/core/kernel/zsh.nix.
      AUTIN_KEY = {
        key = "atuin/key";
        mode = "0400";
      };

      # Used by hosts/hm/lightvela/home.nix (Nezha agent).
      NEZHA_AGENT_SK = {
        key = "nezha/agent_sk";
        mode = "0400";
      };

      # If home/hm ever enables ssh.github, add SSH_GITHUB here and to the
      # encrypted PA file (key = "ssh/github").
    };
  };
}
