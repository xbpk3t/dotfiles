{lib}: let
  escape = lib.escapeShellArg;
  inferHomeDir = {
    pkgs,
    user,
  }:
    if pkgs.stdenv.isDarwin
    then "/Users/${user}"
    else "/home/${user}";
in {
  inherit inferHomeDir;

  mkPassHelpers = {
    pkgs,
    homeDir,
    user ? null,
    scriptName ? "pass-env",
  }: let
    passBin = lib.getExe pkgs.pass;
    headBin = "${lib.getBin pkgs.coreutils}/head";
    sudoBin =
      if pkgs.stdenv.isDarwin
      then "/usr/bin/sudo"
      else lib.getExe pkgs.sudo;
    passStore = "${homeDir}/.password-store";

    script = pkgs.writeShellScriptBin scriptName ''
      #!${pkgs.runtimeShell}
      set -euo pipefail
      export PASSWORD_STORE_DIR=${escape passStore}
      "${passBin}" show "$@" | "${headBin}" -n1
    '';

    baseCommand = path: "${script}/bin/${scriptName} ${escape path}";
    commandAsUser = path:
      if user == null
      then baseCommand path
      else "${sudoBin} -u ${escape user} ${baseCommand path}";
  in {
    inherit script passStore;
    command = baseCommand;
    value = path: ''$(${baseCommand path})'';
    commandAsUser = commandAsUser;
    valueAsUser = path: ''$(${commandAsUser path})'';
  };
}
