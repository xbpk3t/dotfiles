{ mylib, ... }: {
  imports = [
    (mylib.relativeToRoot "secrets/default.nix")
    (mylib.relativeToRoot "home/core")
    (mylib.relativeToRoot "home/base")
    (mylib.relativeToRoot "home/nixos")
  ];

  modules = {
    infra = {
      basePackages.enable = true;
      android.enable = true;
      nh.enable = true;
      networking.enable = true;
    };

    kernel = {
      basePackages.enable = true;
      disk.enable = true;
      BPF.enable = true;
      gpg.enable = true;
      network.enable = true;
      ssh.enable = true;
    };

    devops = {
      basePackages.enable = true;
      cicd.enable = true;
      distrobox.enable = true;
      helix.enable = true;
      rclone.enable = true;
      yazi.enable = true;
      tf = {
        enable = true;
        opentofu.enable = true;
        terramate.enable = true;
        lint.enable = true;
        ansible.enable = true;
      };
      fetch = {
        enable = true;
        driver = "macchina";
      };
    };

    langs = {
      basePackages.enable = true;
      golang = {
        enable = true;
        gotools.enable = true;
      };
      markdown.enable = true;
      python.enable = true;
      rust.enable = true;
      treefmt.enable = true;
      ts.enable = true;
    };

    ms = {
      gateway = {
        enable = true;
        grpc.enable = true;
      };
      helm.enable = true;
    };

    sys.basePackages.enable = true;

    works = {
      crawler.enable = true;
      recon.enable = true;
      test.enable = true;
    };

    zzz.enable = true;

    desktop = {
      stylix.enable = true;
      gnome.enable = true;
      firefox.enable = false;
      ghostty.enable = false;
      zed.enable = false;
    };

    xdg.enable = true;
  };
}
