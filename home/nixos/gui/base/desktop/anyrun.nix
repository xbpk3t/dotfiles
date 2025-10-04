{
  pkgs,
  anyrun,
  ...
}: let
  anyrunPackages = anyrun.packages.${pkgs.system};
in {
  imports = [
    (
      {modulesPath, ...}: {
        # Important! We disable home-manager's module to avoid option
        # definition collisions
        disabledModules = ["${modulesPath}/programs/anyrun.nix"];
      }
    )
    anyrun.homeManagerModules.default
  ];

  programs.anyrun = {
    enable = true;
    # The package should come from the same flake as all the plugins to avoid breakage.
    package = anyrunPackages.anyrun;
    config = {
      # The horizontal position.
      # when using `fraction`, it sets a fraction of the width or height of the screen
      x.fraction = 0.5; # at the middle of the screen
      # The vertical position.
      y.fraction = 0.05; # at the top of the screen
      # The width of the runne r.
      width = {fraction = 0.5;}; # 30% of the screen

      hideIcons = false;
      ignoreExclusiveZones = false;
      layer = "overlay";
      hidePluginInfo = true;

      # if this isn't enabled you must press ESC to exit Anyrun
      closeOnClick = false;
      showResultsImmediately = true;
      maxEntries = null;

      # https://github.com/anyrun-org/anyrun/tree/master/plugins
      plugins = with anyrunPackages; [
        applications # Launch applications
        websearch
        dictionary # Look up word definitions using the Free Dictionary API.
        nix-run # search & run graphical apps from nixpkgs via `nix run`, without installing it.
        # randr         # quickly change monitor configurations on the fly
        rink # A simple calculator plugin
        # symbols # Look up unicode symbols and custom user defined symbols.
        translate # ":zh <text to translate>" Quickly translate text using the Google Translate API.
        # niri-focus # Search for & focus the window via title/appid on Niri
      ];
    };

    # 用 extraConfigFiles 注入自定义 RON（覆盖或追加）
    extraConfigFiles = {
      "applications.ron".text = ''
        Config(
          desktop_actions: false,
          max_entries: 5,
          terminal: Some("kitty"),
        ) '';
      "shell.ron".text = ''
        Config(
          prefix: ";",
          shell: None,
        )
      '';
      "kidex.ron".text = ''
        Config(
          max_entries: 3,
        )
      '';
      "dictionary.ron".text = ''
        Config(
          prefix: ":",
          max_entries: 5,
        )
      '';
      "websearch.ron".text = ''
        Config(
          prefix: "/",
          Custom(
            name: "aliyun",
            url: "https://account.aliyun.com/",
          )
          engines: [Google]
        )
      '';
    };

    extraCss = ''
      * {
          all: unset;
          border-radius: 0;
      }

      window {
          background: rgba(0, 0, 0, 0);
          padding: 48px;
      }

      box.main {
          margin: 48px;
          padding: 24px;
          background-color: rgba(31, 31, 31, .6);
          box-shadow: 0 0 2px 1px rgba(26, 26, 26, 238);
          border: 2px solid #fff;
      }

      text { /* I would center align the text, but GTK doesn't support it */
          border-bottom: 2px solid #fff;
          margin-bottom: 12px;
          padding: 6px;
          font-family: monospace;
      }

      .match {
          padding: 4px;
      }

      .match:selected,
      .match:hover {
          background-color: rgba(255, 255, 255, .2);
      }

      label.match-title {
          font-weight: bold;
      }
    '';
  };
}
