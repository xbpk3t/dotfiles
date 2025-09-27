{
  inputs,
  mylib,
  username,
  ...
}: {
  # Home Manager system configuration
  useGlobalPkgs = true;
  useUserPackages = true;
  backupFileExtension = "hm-bak";

  # Pass special arguments to home-manager
  extraSpecialArgs = {
    inherit username inputs mylib;
    hostname = "MacBook-Pro";
    mail = "yyzw@live.com";
  };

  # User configuration
  users.${username} = {
    home = {
      inherit username;
      homeDirectory = "/Users/${username}";
      stateVersion = "24.05";
    };

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # Import base configurations
    imports = [../base] ++ (mylib.scanPaths ./.);
  };
}
