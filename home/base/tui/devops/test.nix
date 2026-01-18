{pkgs, ...}: {
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/k6
    k6
    # vegeta
    # speedtest-cli

    # hyperfine

    # https://mynixos.com/nixpkgs/package/jmeter

    # https://mynixos.com/nixpkgs/package/playwright
    playwright
  ];
}
