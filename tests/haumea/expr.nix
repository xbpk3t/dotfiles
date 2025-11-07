{
  haumea,
  lib,
  pkgs ? null,
  ...
}: let
  moduleInputs = {
    inherit lib;
    # pkgs is optional for the fixtures but exposing it makes future tests easy.
    inherit pkgs;
  };
in
  haumea.lib.load {
    src = ../../fixtures/haumea;
    inputs = moduleInputs;
  }
