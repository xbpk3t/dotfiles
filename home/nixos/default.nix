{
  inputs,
  mylib,
  username,
  host,
  profile,
  mail,
  ...
}: {
  # Home Manager system configuration
  useGlobalPkgs = true;
  useUserPackages = true;
  backupFileExtension = "hm-bak";

  # Pass special arguments to home-manager
  extraSpecialArgs = {
    inherit inputs mylib username host profile mail;
  };

  # User configuration
  users.${username} = {
    home = {
      inherit username;
      homeDirectory = "/home/${username}";
      stateVersion = "24.05";
    };

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # Import base and NixOS-specific configurations
    imports = [../base] ++ (mylib.scanPaths ./.);
  };
}
