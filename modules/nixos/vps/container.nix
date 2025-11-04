{lib, ...}: {
  boot = {
    isContainer = true;
    loader = {
      grub.enable = lib.mkForce false;
      systemd-boot.enable = lib.mkForce false;
      efi.canTouchEfiVariables = lib.mkForce false;
    };
  };

  documentation = {
    enable = lib.mkDefault false;
    nixos.enable = lib.mkDefault false;
    man.enable = lib.mkDefault false;
    doc.enable = lib.mkDefault false;
    info.enable = lib.mkDefault false;
  };

  systemd.services."getty@tty1".enable = lib.mkForce false;
  systemd.services."serial-getty@ttyS0".enable = lib.mkForce false;

  # Ensure the container build target is available with Podman defaults.
  virtualisation.oci-containers.backend = lib.mkDefault "podman";
}
