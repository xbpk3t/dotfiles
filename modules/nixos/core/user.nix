{
  pkgs,
  username,
  ...
}: {
  users.mutableUsers = true;
  users.users.${username} = {
    isNormalUser = true;
    description = "";
    extraGroups = [
      "adbusers"
      "docker" #access to docker as non-root
      "libvirtd" #Virt manager/QEMU access
      "lp"
      "networkmanager"
      "scanner"
      "wheel" #subdo access
      "vboxusers" #Virtual Box
    ];
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
  };
  nix.settings.allowed-users = ["${username}"];
}
