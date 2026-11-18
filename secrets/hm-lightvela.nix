{
  lib,
  mylib,
  ...
}:
{
  imports = [ ./default.nix ];

  # PA-only full copy. Encrypted to the PA age key
  # (/root/.config/sops/age/keys.txt), not the fleet master key.
  sops = {
    defaultSopsFile = lib.mkForce (mylib.relativeToRoot "secrets/hm-lightvela.yaml");
    age.keyFile = lib.mkForce "/root/.config/sops/age/keys.txt";
  };
}
