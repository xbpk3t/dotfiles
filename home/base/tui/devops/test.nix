{pkgs, ...}: {
  home.packages = with pkgs; [
    k6
    # vegeta
    # speedtest-cli

    # hyperfine
  ];
}
