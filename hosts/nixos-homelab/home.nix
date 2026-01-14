{...}: {
  modules.extra = {
    jetbrains-remote.enable = true;
  };

  modules.AI = {
    codex.enable = true;
  };

  modules.ssh = {
    enable = true;
    hosts = {
      # github.enable = true;
      hk-claw.enable = true;
      hk-hdy.enable = true;
      LA.enable = true;
    };
  };

  modules.langs = {
    lsp.enable = true;
  };
}
