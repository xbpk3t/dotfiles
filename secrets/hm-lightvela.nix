{
  lib,
  mylib,
  ...
}:
{
  # PA-only secret subset. Do not import ./default.nix: the PA is vendor-managed
  # and must not receive the full fleet secret set. Keep this list in sync with
  # the modules imported by home/hm/default.nix.
  sops = {
    defaultSopsFile = mylib.relativeToRoot "secrets/hm-lightvela.yaml";
    age.keyFile = "/root/.config/sops/age/keys.txt";

    # sops-nix's Home Manager activation needs a usable PATH (getconf); without
    # this the module defaults to an empty PATH on some platforms. The PA is a
    # plain Debian container, so only the system paths exist.
    environment.PATH = lib.mkForce "/usr/bin:/bin:/usr/sbin:/sbin";

    secrets = {
      # Used by home/core/devops/gh.nix.
      GITHUB_TOKEN.key = "API/github";
      RESEND_TOKEN.key = "resend/pwd";

      # Used by home/core/kernel/zsh.nix.
      AUTIN_KEY.key = "atuin/key";

      # Used by hosts/hm/lightvela/home.nix (Nezha agent).
      NEZHA_AGENT_SK.key = "nezha/agent_sk";

      # If home/hm ever enables ssh.github, add SSH_GITHUB here and to the
      # encrypted PA file (key = "ssh/github").
    };
  };
}
