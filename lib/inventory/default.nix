{lib}: let
  data = import ./data.nix;
  utils = import ./utils.nix {
    inherit lib;
    inventoryData = data;
  };
in
  utils
  // {
    inherit data;
  }
