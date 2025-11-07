{...}: let
  mkModules = modules: map (path: "modules/" + path) modules;
  mkTags = attrs: attrs // {platform = "darwin";};
in {
  darwinConfigurations.macbook-pro = {
    system = "x86_64-darwin";
    modules = mkModules [
      "base"
      "darwin/base"
      "darwin/work"
    ];
    tags = mkTags {
      formFactor = "laptop";
      ui = "aqua";
    };
  };
}
