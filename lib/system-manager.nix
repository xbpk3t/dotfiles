{
  inputs,
  system-modules ? [ ],
  # system-manager 新 API 用 specialArgs；extraSpecialArgs 已 deprecated。
  specialArgs ? { },
  overlays ? [ ],
  ...
}:
inputs.system-manager.lib.makeSystemConfig {
  modules = system-modules;
  inherit overlays specialArgs;
}
