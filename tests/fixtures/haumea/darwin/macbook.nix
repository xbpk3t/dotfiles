{...}: let
  mkModules = modules: map (path: "modules/" + path) modules;
  mkHomeModules = modules: map (path: "home/" + path) modules;
  mkTags = attrs: attrs // {platform = "darwin";};
in {
  darwinConfigurations.macbook-pro = {
    system = "aarch64-darwin";
    modules = mkModules [
      # The Darwin stack is now consolidated under modules/darwin
      "darwin"
    ];
    home-modules = mkHomeModules [
      # Darwin home configuration mirrors flake output: home/base/core + home/darwin
      "base/core"
      "darwin"
    ];
    tags = mkTags {
      formFactor = "laptop";
      ui = "aqua";
    };
  };
}
