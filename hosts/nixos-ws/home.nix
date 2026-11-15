_: {
  modules = {
    infra = {
      basePackages.enable = true;
      android.enable = false;
      nh.enable = true;
      networking.enable = true;
    };

    kernel = {
      basePackages.enable = true;
      disk.enable = true;
      gpg.enable = true;
      network.enable = true;
      ssh.enable = true;
    };

    ms = {
      gateway = {
        enable = true;
        caddy.enable = true;
        grpc.enable = true;
      };
      k8s = {
        enable = true;
        core.enable = true;
        cluster.enable = true;
      };
    };

    desktop = {
      stylix.enable = true;

      gnome.enable = true;

      zed.enable = false;

      ghostty.enable = false;

      firefox.enable = false;
    };

    devops = {
      basePackages.enable = true;
      cf.enable = true;
      helix.enable = true;
      tf = {
        enable = true;
        opentofu.enable = true;
        terramate.enable = true;
        lint.enable = true;
        ansible.enable = true;
      };
      yazi.enable = true;
      ssh = {
        enable = true;
        github.enable = true;
      };
    };

    langs = {
      basePackages.enable = true;
      golang.enable = true;
      markdown.enable = true;
      python.enable = true;
      rust.enable = true;
      treefmt.enable = true;
      ts.enable = true;
    };

    xdg.enable = true;
  };
}
