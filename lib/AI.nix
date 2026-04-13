{lib, ...}: let
  regexMetaChars = ["\\" "." "+" "*" "?" "^" "$" "(" ")" "[" "]" "{" "}" "|"];
  escapeRegex = lib.replaceStrings regexMetaChars (map (char: "\\${char}") regexMetaChars);
  mkCodexProviderEnvValue = {
    config,
    provider,
  }:
    if provider ? sk
    then ''$(cat ${(builtins.getAttr provider.sk config.sops.secrets).path})''
    else throw "Codex provider `${provider.env or "unknown"}` must define `sk`.";
in {
  mkExactNameRegex = names: "^(${lib.concatStringsSep "|" (map escapeRegex names)})$";

  mkCodexModelProviders = providers:
    lib.mapAttrs (name: provider: {
      inherit name;
      base_url = provider.url;
      env_key = provider.env;
      wire_api = provider.wireApi or "responses";
    })
    providers;

  mkCodexProfiles = providers:
    lib.mapAttrs (name: provider: {
      model_provider = name;
      model = provider.model or "gpt-5.4";
    })
    providers;

  mkCodexSessionVariables = {
    config,
    providers,
  }:
    lib.mapAttrs'
    (_: provider: lib.nameValuePair provider.env (mkCodexProviderEnvValue {inherit config provider;}))
    providers;

  mkCodexShellAliases = providers:
    lib.mapAttrs'
    (name: _provider:
      lib.nameValuePair
      "codex-${name}"
      "codex --profile ${name}")
    providers;
}
