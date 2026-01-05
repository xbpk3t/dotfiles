{
  lib,
  inputs,
  ...
} @ args: let
  inherit (inputs) haumea;

  # Contains all the flake outputs of this system architecture.
  # Filter out reserved names that haumea cannot handle
  filteredInputs = builtins.removeAttrs args ["self" "super" "root"];
  data = haumea.lib.load {
    src = ./src;
    inputs = filteredInputs;
  };
  # nix file names is redundant, so we remove it.
  dataWithoutPaths = builtins.attrValues data;

  # Merge all the machine's data into a single attribute set.
  outputs = {
    nixosConfigurations = lib.attrsets.mergeAttrsList (
      map (it: it.nixosConfigurations or {}) dataWithoutPaths
    );
    colmena = lib.attrsets.mergeAttrsList (map (it: it.colmena or {}) dataWithoutPaths);
  };
in
  outputs
  // {
    inherit data; # for debugging purposes

    evalTests = {};
  }
