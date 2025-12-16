{...}: {
  # https://wiki.nixos.org/wiki/Distrobox
  # https://mynixos.com/home-manager/options/programs.distrobox

  # TODO  luck profile: The module programs.distrobox does not support your platform. It only supports
  #
  #  home.packages = with pkgs; [distrobox];
  #
  #  programs.distrobox = {
  #    enable = true;
  #    package = pkgs.distrobox;
  #
  #    # enableSystemdUnit requires at least one container to be defined
  #    # Disabled for now since no containers are configured
  #    enableSystemdUnit = false;
  #    # containers = {
  #    #      my-distrobox = {
  #    #        image = "ghcr.io/ublue-os/ubuntu-toolbox";
  #    #        additional_packages = "git vim curl";
  #    #        entry = true;
  #    #      };
  #
  #    #      kali = {
  #    #        image = "docker.io/kalilinux/kali-rolling:latest";
  #    #        additional_packages = "kali-linux-core kali-linux-default";
  #    #      };
  #    #      debian = {
  #    #        image = "docker.io/debian:latest";
  #    #        additional_packages = "systemd";
  #    #      };
  #    # };
  #
  #    # ~/.local/share/containers/
  #    #    settings = {
  #    #      container_additional_volumes = [
  #    #        "/nix/store:/nix/store:r"
  #    #        "/etc/profiles/per-user:/etc/profiles/per-user:r"
  #    #      ];
  #    #      container_image_default = "registry.opensuse.org/opensuse/distrobox-packaging:latest";
  #    #      container_command = "sh -norc";
  #    #    };
  #  };
}
