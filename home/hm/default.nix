{
  mylib,
  ...
}:
{
  imports = [
    # herdr-core is deliberately not imported: the sh/closure path owns
    # ~/.local/bin/{hc,herdr-core} and /usr/local/bin wrappers. If HM installed
    # its own hc, ~/.nix-profile/bin would shadow those wrappers and break the
    # socket selection.

    # home/core: curated for vendor PAs. No db/ms/cntr/taskfile/init; those
    # are either unconditional package sets or tied to the dotfiles path.
    (mylib.relativeToRoot "home/core/kernel")
    (mylib.relativeToRoot "home/core/langs")
    (mylib.relativeToRoot "home/core/devops/btop.nix")
    (mylib.relativeToRoot "home/core/devops/fastfetch.nix")
    (mylib.relativeToRoot "home/core/devops/git.nix")
    (mylib.relativeToRoot "home/core/devops/gh.nix")
    (mylib.relativeToRoot "home/core/devops/journalctl.nix")
    (mylib.relativeToRoot "home/core/devops/lazygit.nix")
    (mylib.relativeToRoot "home/core/devops/ssh.nix")
    (mylib.relativeToRoot "home/core/devops/worktrunk.nix")
  ];

  modules.devops = {
    # Tailnet SSH entries only; GitHub identity/key is intentionally off.
    ssh = {
      enable = true;
      github.enable = false;
    };
  };

  # The sh/closure path owns ~/.local/bin/{hc,herdr-core} and /usr/local/bin.
  # HM must not replace those socket-aware wrappers; see
  # hosts/_base/hm/bootstrap.sh.
}
