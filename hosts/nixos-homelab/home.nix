{ ... }:
{
  modules.infra = {
    nh.enable = true;
    networking.enable = true;
  };

  modules.extra = {
    zed-remote.enable = true;
  };

  modules.AI = {
    codex.enable = false;
    skills.enable = false;
  };

  modules.devops.ssh = {
    enable = true;
    hosts = {
      # github.enable = true;
      hk-hdy.enable = true;
      LA.enable = true;
    };
  };

  modules.langs = {
    lsp.enable = true;
  };
}
