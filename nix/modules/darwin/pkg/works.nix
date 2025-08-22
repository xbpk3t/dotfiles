{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # crawler
    katana

    # test
    k6
  ];
}
