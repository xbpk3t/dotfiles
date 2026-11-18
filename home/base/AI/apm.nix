{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.AI.apm;
in
{
  options.modules.AI.apm.enable = lib.mkEnableOption "APM (agent package manager)";

  # TODO(llm-agents#12494): switch home.packages to
  # `inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.apm-bin`
  # (or whatever name upstream chooses) once
  # https://github.com/numtide/llm-agents.nix/pull/12494 lands, then delete
  # `pkgs/apm-bin` and the four `apm-bin-*` entries in nvfetcher.toml.
  #
  # Why a local package exists:
  # - llm-agents' `apm` is `python3Packages.buildPythonApplication`; its
  #   closure is ~1G+ because it carries a full Python environment.
  # - nixpkgs' `apm-cli` is 463.5 MiB and sets
  #   `pythonRemoveDeps = [ "llm-github-models" ]`, so GitHub Models support
  #   is missing.
  # - microsoft/apm publishes official standalone PyInstaller bundles:
  #   x86_64-linux tarball ~19 MiB / ~33 MiB unpacked, aarch64-darwin
  #   tarball ~24 MiB. `pkgs.apm-bin` wraps that release, keeps the full
  #   feature set, and is still Nix-pinned via nvfetcher.
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.apm-bin ];
  };
}
