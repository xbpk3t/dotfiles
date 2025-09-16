{pkgs, ...}: {
  programs.yazi = {
    enable = true;

    # Use the latest yazi package
    package = pkgs.yazi;

    # Enable shell integrations
    enableBashIntegration = true;

    # Note: Theme and colors are now managed by Stylix
    # This removes the need for manual theme configuration

    settings = {
      mgr = {
        show_hidden = true;
        sort_dir_first = true;
        linemode = "mtime";

        ratio = [
          1
          2
          4
        ];
      };

      preview = {
        tab_size = 4;
        image_filter = "lanczos3";
        max_width = 1920;
        max_height = 1080;
        image_quality = 90;
      };
    };

    keymap = {
      mgr.prepend_keymap = [
        {
          run = "remove --force";
          on = ["d"];
        }
      ];
    };
  };
}
