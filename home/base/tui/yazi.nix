{pkgs, ...}: let
  defaultEditor = "${pkgs.neovim}/bin/nvim";
  yaziEditWrapper = pkgs.writeShellScriptBin "yazi-open-editor" ''
    editor="''${EDITOR:-${defaultEditor}}"
    exec "$editor" "$@"
  '';
in {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    # enableZshIntegration = true;
    # enableFishIntegration = true;

    shellWrapperName = "yy";

    settings = {
      mgr = {
        ratio = [1 4 3];
        sort_by = "alphabetical";
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = true;
        sort_translit = false;
        linemode = "none";
        show_hidden = false;
        show_symlink = true;
        scrolloff = 5;
        mouse_events = ["click" "scroll"];
        title_format = "Yazi: {cwd}";
      };
      preview = {
        wrap = "no";
        tab_size = 2;
        max_width = 600;
        max_height = 900;
        cache_dir = "";
        image_delay = 30;
        image_filter = "triangle";
        image_quality = 75;
        sixel_fraction = 15;
        ueberzug_scale = 1;
        ueberzug_offset = [0 0 0 0];
      };
      opener = {
        edit = [
          {
            run = ''${yaziEditWrapper}/bin/yazi-open-editor "$@"'';
            desc = "Open with \$EDITOR (fallback nvim)";
            block = true;
            for = "unix";
          }
          {
            run = "code %*";
            orphan = true;
            desc = "code";
            for = "windows";
          }
          {
            run = "code -w %*";
            block = true;
            desc = "code (block)";
            for = "windows";
          }
        ];
        open = [
          {
            run = ''xdg-open "$1"'';
            desc = "Open";
            for = "linux";
          }
          {
            run = ''open "$@"'';
            desc = "Open";
            for = "macos";
          }
          {
            run = ''start "" "%1"'';
            orphan = true;
            desc = "Open";
            for = "windows";
          }
          {
            run = ''termux-open "$1"'';
            desc = "Open";
            for = "android";
          }
        ];
        reveal = [
          {
            run = ''xdg-open "$(dirname "$1")"'';
            desc = "Reveal";
            for = "linux";
          }
          {
            run = ''open -R "$1"'';
            desc = "Reveal";
            for = "macos";
          }
          {
            run = ''explorer /select,"%1"'';
            orphan = true;
            desc = "Reveal";
            for = "windows";
          }
          {
            run = ''termux-open "$(dirname "$1")"'';
            desc = "Reveal";
            for = "android";
          }
          {
            run = ''exiftool "$1"; echo "Press enter to exit"; read _'';
            block = true;
            desc = "Show EXIF";
            for = "unix";
          }
        ];
        extract = [
          {
            run = ''ya pub extract --list "$@"'';
            desc = "Extract here";
            for = "unix";
          }
          {
            run = "ya pub extract --list %*";
            desc = "Extract here";
            for = "windows";
          }
        ];
        play = [
          {
            run = ''mpv --force-window "$@"'';
            orphan = true;
            for = "unix";
          }
          {
            run = "mpv --force-window %*";
            orphan = true;
            for = "windows";
          }
          {
            run = ''mediainfo "$1"; echo "Press enter to exit"; read _'';
            block = true;
            desc = "Show media info";
            for = "unix";
          }
        ];

        # 图片预览
        # Use yazi's built-in image preview instead of external viewers
        # This allows arrow key navigation between images
        # Yazi automatically selects the appropriate preview method based on terminal capabilities
        # Supported protocols: Kitty, iTerm2, WezTerm, Sixel, etc.
        # For more info: https://yazi-rs.github.io/docs/image-preview/
        #
        # Note: Removed imv external viewer as it doesn't support arrow key navigation
        # Yazi's built-in preview works with j/k or arrow keys to navigate between images
        preview_image = [];
      };
      open = {
        rules = [
          {
            name = "*/";
            use = ["edit" "open" "reveal"];
          }
          {
            mime = "text/*";
            use = ["edit" "reveal"];
          }
          #          {
          #            mime = "image/*";
          #            use = ["open" "reveal"];
          #          }
          {
            mime = "image/*";
            use = ["preview_image" "open" "reveal"];
          }
          {
            mime = "{audio,video}/*";
            use = ["play" "reveal"];
          }
          {
            mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}";
            use = ["extract" "reveal"];
          }
          {
            mime = "application/{json,ndjson}";
            use = ["edit" "reveal"];
          }
          {
            mime = "*/javascript";
            use = ["edit" "reveal"];
          }
          {
            mime = "inode/empty";
            use = ["edit" "reveal"];
          }
          {
            name = "*";
            use = ["open" "reveal"];
          }
        ];
      };
      tasks = {
        micro_workers = 10;
        macro_workers = 10;
        bizarre_retry = 3;
        image_alloc = 536870912;
        image_bound = [0 0];
        suppress_preload = false;
      };
      plugin = {
        fetchers = [
          {
            id = "mime";
            name = "*";
            run = "mime";
            prio = "high";
          }
        ];
        spotters = [
          {
            name = "*/";
            run = "folder";
          }
          {
            mime = "text/*";
            run = "code";
          }
          {
            mime = "application/{mbox,javascript,wine-extension-ini}";
            run = "code";
          }
          {
            mime = "image/{avif,hei?,jxl,svg+xml}";
            run = "magick";
          }
          {
            mime = "image/*";
            run = "image";
          }
          {
            mime = "video/*";
            run = "video";
          }
          {
            name = "*";
            run = "file";
          }
        ];
        preloaders = [
          {
            mime = "image/{avif,hei?,jxl,svg+xml}";
            run = "magick";
          }
          {
            mime = "image/*";
            run = "image";
          }
          {
            mime = "video/*";
            run = "video";
          }
          {
            mime = "application/pdf";
            run = "pdf";
          }
          {
            mime = "font/*";
            run = "font";
          }
          {
            mime = "application/ms-opentype";
            run = "font";
          }
        ];
        previewers = [
          {
            name = "*/";
            run = "folder";
            sync = true;
          }
          {
            mime = "text/*";
            run = "code";
          }
          {
            mime = "application/{mbox,javascript,wine-extension-ini}";
            run = "code";
          }
          {
            mime = "application/{json,ndjson}";
            run = "json";
          }
          {
            mime = "image/{avif,hei?,jxl,svg+xml}";
            run = "magick";
          }
          {
            mime = "image/*";
            run = "image";
          }
          {
            mime = "video/*";
            run = "video";
          }
          {
            mime = "application/pdf";
            run = "pdf";
          }
          {
            mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}";
            run = "archive";
          }
          {
            mime = "application/{debian*-package,redhat-package-manager,rpm,android.package-archive}";
            run = "archive";
          }
          {
            name = "*.{AppImage,appimage}";
            run = "archive";
          }
          {
            mime = "application/{iso9660-image,qemu-disk,ms-wim,apple-diskimage}";
            run = "archive";
          }
          {
            mime = "application/virtualbox-{vhd,vhdx}";
            run = "archive";
          }
          {
            name = "*.{img,fat,ext,ext2,ext3,ext4,squashfs,ntfs,hfs,hfsx}";
            run = "archive";
          }
          {
            mime = "font/*";
            run = "font";
          }
          {
            mime = "application/ms-opentype";
            run = "font";
          }
          {
            mime = "inode/empty";
            run = "empty";
          }
          {
            name = "*";
            run = "file";
          }
        ];
        prepend_fetchers = [
          {
            id = "git";
            name = "*";
            run = "git";
          }
          {
            id = "git";
            name = "*/";
            run = "git";
          }
        ];
      };
      input = {
        cursor_blink = false;
        cd_title = "Change directory:";
        cd_origin = "top-center";
        cd_offset = [0 2 50 3];
        create_title = ["Create:" "Create (dir):"];
        create_origin = "top-center";
        create_offset = [0 2 50 3];
        rename_title = "Rename:";
        rename_origin = "hovered";
        rename_offset = [0 1 50 3];
        filter_title = "Filter:";
        filter_origin = "top-center";
        filter_offset = [0 2 50 3];
        find_title = ["Find next:" "Find previous:"];
        find_origin = "top-center";
        find_offset = [0 2 50 3];
        search_title = "Search via {n}:";
        search_origin = "top-center";
        search_offset = [0 2 50 3];
        shell_title = ["Shell:" "Shell (block):"];
        shell_origin = "top-center";
        shell_offset = [0 2 50 3];
      };
      confirm = {
        trash_title = "Trash {n} selected file{s}?";
        trash_origin = "center";
        trash_offset = [0 0 70 20];
        delete_title = "Permanently delete {n} selected file{s}?";
        delete_origin = "center";
        delete_offset = [0 0 70 20];
        overwrite_title = "Overwrite file?";
        overwrite_content = "Will overwrite the following file:";
        overwrite_origin = "center";
        overwrite_offset = [0 0 50 15];
        quit_title = "Quit?";
        quit_content = "The following tasks are still running, are you sure you want to quit?";
        quit_origin = "center";
        quit_offset = [0 0 50 15];
      };
      pick = {
        open_title = "Open with:";
        open_origin = "hovered";
        open_offset = [0 1 50 7];
      };
      which = {
        sort_by = "none";
        sort_sensitive = false;
        sort_reverse = false;
        sort_translit = false;
      };
    };

    #I don't get that.. normally it's a add file (touch) or A for add folder (or mkdir) r for RENAME (R for rename the file extension) y for yank (vim wording for copy) x for cut (like windoof Ctrl + x) v for visual mode (select more files or folders for copy or delete) d for delete trash and D for perma delete. I think it's quite intuitive and way faster than typing the command.
    #我不明白……通常情况下，它是添加文件（touch）或 A 添加文件夹（或 mkdir），r 重命名（R 重命名文件扩展名），y 复制（vim 中复制的写法），x 剪切（类似 windows 的 Ctrl + x），v 可视模式（选择更多文件或文件夹进行复制或删除），d 删除垃圾文件，D 永久删除。我觉得这很直观，而且比直接输入命令快得多。
    keymap = {
      keymap = [
        {
          on = "<Esc>";
          run = "escape";
          desc = "Exit visual mode, clear selected, or cancel search";
        }
        {
          on = "<C-[>";
          run = "escape";
          desc = "Exit visual mode, clear selected, or cancel search";
        }
        {
          on = "q";
          run = "quit";
          desc = "Quit the process";
        }
        {
          on = "Q";
          run = "quit --no-cwd-file";
          desc = "Quit the process without outputting cwd-file";
        }
        {
          on = "<C-c>";
          run = "close";
          desc = "Close the current tab, or quit if it's last";
        }
        {
          on = "<C-z>";
          run = "suspend";
          desc = "Suspend the process";
        }
        {
          on = "k";
          run = "arrow -1";
          desc = "Move cursor up";
        }
        {
          on = "j";
          run = "arrow 1";
          desc = "Move cursor down";
        }
        {
          on = "<Up>";
          run = "arrow -1";
          desc = "Move cursor up";
        }
        {
          on = "<Down>";
          run = "arrow 1";
          desc = "Move cursor down";
        }
        {
          on = "<C-u>";
          run = "arrow -50%";
          desc = "Move cursor up half page";
        }
        {
          on = "<C-d>";
          run = "arrow 50%";
          desc = "Move cursor down half page";
        }
        {
          on = "<C-b>";
          run = "arrow -100%";
          desc = "Move cursor up one page";
        }
        {
          on = "<C-f>";
          run = "arrow 100%";
          desc = "Move cursor down one page";
        }
        {
          on = "<S-PageUp>";
          run = "arrow -50%";
          desc = "Move cursor up half page";
        }
        {
          on = "<S-PageDown>";
          run = "arrow 50%";
          desc = "Move cursor down half page";
        }
        {
          on = "<PageUp>";
          run = "arrow -100%";
          desc = "Move cursor up one page";
        }
        {
          on = "<PageDown>";
          run = "arrow 100%";
          desc = "Move cursor down one page";
        }
        {
          on = ["g" "g"];
          run = "arrow top";
          desc = "Move cursor to the top";
        }
        {
          on = "G";
          run = "arrow bot";
          desc = "Move cursor to the bottom";
        }
        {
          on = "h";
          run = "leave";
          desc = "Go back to the parent directory";
        }
        {
          on = "l";
          run = "enter";
          desc = "Enter the child directory";
        }
        {
          on = "<Left>";
          run = "leave";
          desc = "Go back to the parent directory";
        }
        {
          on = "<Right>";
          run = "enter";
          desc = "Enter the child directory";
        }
        {
          on = "H";
          run = "back";
          desc = "Go back to the previous directory";
        }
        {
          on = "L";
          run = "forward";
          desc = "Go forward to the next directory";
        }
        #  {
        #    on = "<Space>";
        #    run = ["toggle" "arrow 1"];
        #    desc = "Toggle the current selection state";
        #  }

        {
          on = "<Space>";
          run = "open --rule=preview_image";
          desc = "Preview image in full screen";
        }
        {
          on = "<C-a>";
          run = "toggle_all --state=on";
          desc = "Select all files";
        }
        {
          on = "<C-r>";
          run = "toggle_all";
          desc = "Invert selection of all files";
        }
        {
          on = "v";
          run = "visual_mode";
          desc = "Enter visual mode (selection mode)";
        }
        {
          on = "V";
          run = "visual_mode --unset";
          desc = "Enter visual mode (unset mode)";
        }
        {
          on = "K";
          run = "seek -5";
          desc = "Seek up 5 units in the preview";
        }
        {
          on = "J";
          run = "seek 5";
          desc = "Seek down 5 units in the preview";
        }
        {
          on = "<Tab>";
          run = "spot";
          desc = "Spot hovered file";
        }
        {
          on = "o";
          run = "open";
          desc = "Open selected files";
        }
        {
          on = "O";
          run = "open --interactive";
          desc = "Open selected files interactively";
        }
        {
          on = "<Enter>";
          run = "open";
          desc = "Open selected files";
        }
        {
          on = "<S-Enter>";
          run = "open --interactive";
          desc = "Open selected files interactively";
        }
        {
          on = "y";
          run = "yank";
          desc = "Yank selected files (copy)";
        }
        {
          on = "x";
          run = "yank --cut";
          desc = "Yank selected files (cut)";
        }
        {
          on = "p";
          run = "paste";
          desc = "Paste yanked files";
        }
        {
          on = "P";
          run = "paste --force";
          desc = "Paste yanked files (overwrite if the destination exists)";
        }
        {
          on = "-";
          run = "link";
          desc = "Symlink the absolute path of yanked files";
        }
        {
          on = "_";
          run = "link --relative";
          desc = "Symlink the relative path of yanked files";
        }
        {
          on = "<C-->";
          run = "hardlink";
          desc = "Hardlink yanked files";
        }
        {
          on = "Y";
          run = "unyank";
          desc = "Cancel the yank status";
        }
        {
          on = "X";
          run = "unyank";
          desc = "Cancel the yank status";
        }
        {
          on = "d";
          run = "remove";
          desc = "Trash selected files";
        }
        {
          on = "D";
          run = "remove --permanently";
          desc = "Permanently delete selected files";
        }
        {
          on = "a";
          run = "create";
          desc = "Create a file (ends with / for directories)";
        }
        {
          on = "r";
          run = "rename --cursor=before_ext";
          desc = "Rename selected file(s)";
        }
        {
          on = ";";
          run = "shell --interactive";
          desc = "Run a shell command";
        }
        {
          on = ":";
          run = "shell --block --interactive";
          desc = "Run a shell command (block until finishes)";
        }
        {
          on = ".";
          run = "hidden toggle";
          desc = "Toggle the visibility of hidden files";
        }
        {
          on = "s";
          run = "search --via=fd";
          desc = "Search files by name via fd";
        }
        {
          on = "S";
          run = "search --via=rg";
          desc = "Search files by content via ripgrep";
        }
        {
          on = "<C-s>";
          run = "escape --search";
          desc = "Cancel the ongoing search";
        }
        {
          on = "z";
          run = "plugin zoxide";
          desc = "Jump to a directory via zoxide";
        }
        {
          on = "Z";
          run = "plugin fzf";
          desc = "Jump to a file/directory via fzf";
        }
        {
          on = ["m" "s"];
          run = "linemode size";
          desc = "Linemode: size";
        }
        {
          on = ["m" "p"];
          run = "linemode permissions";
          desc = "Linemode: permissions";
        }
        {
          on = ["m" "b"];
          run = "linemode btime";
          desc = "Linemode: btime";
        }
        {
          on = ["m" "m"];
          run = "linemode mtime";
          desc = "Linemode: mtime";
        }
        {
          on = ["m" "o"];
          run = "linemode owner";
          desc = "Linemode: owner";
        }
        {
          on = ["m" "n"];
          run = "linemode none";
          desc = "Linemode: none";
        }
        {
          on = ["c" "c"];
          run = "copy path";
          desc = "Copy the file path";
        }
        {
          on = ["c" "d"];
          run = "copy dirname";
          desc = "Copy the directory path";
        }
        {
          on = ["c" "f"];
          run = "copy filename";
          desc = "Copy the filename";
        }
        {
          on = ["c" "n"];
          run = "copy name_without_ext";
          desc = "Copy the filename without extension";
        }
        {
          on = "f";
          run = "filter --smart";
          desc = "Filter files";
        }
        {
          on = "/";
          run = "find --smart";
          desc = "Find next file";
        }
        {
          on = "?";
          run = "find --previous --smart";
          desc = "Find previous file";
        }
        {
          on = "n";
          run = "find_arrow";
          desc = "Goto the next found";
        }
        {
          on = "N";
          run = "find_arrow --previous";
          desc = "Goto the previous found";
        }
        {
          on = ["," "m"];
          run = ["sort mtime --reverse=no" "linemode mtime"];
          desc = "Sort by modified time";
        }
        {
          on = ["," "M"];
          run = ["sort mtime --reverse" "linemode mtime"];
          desc = "Sort by modified time (reverse)";
        }
        {
          on = ["," "b"];
          run = ["sort btime --reverse=no" "linemode btime"];
          desc = "Sort by birth time";
        }
        {
          on = ["," "B"];
          run = ["sort btime --reverse" "linemode btime"];
          desc = "Sort by birth time (reverse)";
        }
        {
          on = ["," "e"];
          run = "sort extension --reverse=no";
          desc = "Sort by extension";
        }
        {
          on = ["," "E"];
          run = "sort extension --reverse";
          desc = "Sort by extension (reverse)";
        }
        {
          on = ["," "a"];
          run = "sort alphabetical --reverse=no";
          desc = "Sort alphabetically";
        }
        {
          on = ["," "A"];
          run = "sort alphabetical --reverse";
          desc = "Sort alphabetically (reverse)";
        }
        {
          on = ["," "n"];
          run = "sort natural --reverse=no";
          desc = "Sort naturally";
        }
        {
          on = ["," "N"];
          run = "sort natural --reverse";
          desc = "Sort naturally (reverse)";
        }
        {
          on = ["," "s"];
          run = ["sort size --reverse=no" "linemode size"];
          desc = "Sort by size";
        }
        {
          on = ["," "S"];
          run = ["sort size --reverse" "linemode size"];
          desc = "Sort by size (reverse)";
        }
        {
          on = ["," "r"];
          run = "sort random --reverse=no";
          desc = "Sort randomly";
        }
        {
          on = ["g" "h"];
          run = "cd ~";
          desc = "Go home";
        }
        {
          on = ["g" "c"];
          run = "cd ~/.config";
          desc = "Goto ~/.config";
        }
        {
          on = ["g" "d"];
          run = "cd ~/Downloads";
          desc = "Goto ~/Downloads";
        }
        {
          on = ["g" "<Space>"];
          run = "cd --interactive";
          desc = "Jump interactively";
        }
        {
          on = "t";
          run = "tab_create --current";
          desc = "Create a new tab with CWD";
        }
        {
          on = "1";
          run = "tab_switch 0";
          desc = "Switch to the first tab";
        }
        {
          on = "2";
          run = "tab_switch 1";
          desc = "Switch to the second tab";
        }
        {
          on = "3";
          run = "tab_switch 2";
          desc = "Switch to the third tab";
        }
        {
          on = "4";
          run = "tab_switch 3";
          desc = "Switch to the fourth tab";
        }
        {
          on = "5";
          run = "tab_switch 4";
          desc = "Switch to the fifth tab";
        }
        {
          on = "6";
          run = "tab_switch 5";
          desc = "Switch to the sixth tab";
        }
        {
          on = "7";
          run = "tab_switch 6";
          desc = "Switch to the seventh tab";
        }
        {
          on = "8";
          run = "tab_switch 7";
          desc = "Switch to the eighth tab";
        }
        {
          on = "9";
          run = "tab_switch 8";
          desc = "Switch to the ninth tab";
        }
        {
          on = "[";
          run = "tab_switch -1 --relative";
          desc = "Switch to the previous tab";
        }
        {
          on = "]";
          run = "tab_switch 1 --relative";
          desc = "Switch to the next tab";
        }
        {
          on = "{";
          run = "tab_swap -1";
          desc = "Swap current tab with previous tab";
        }
        {
          on = "}";
          run = "tab_swap 1";
          desc = "Swap current tab with next tab";
        }
        {
          on = "w";
          run = "tasks_show";
          desc = "Show task manager";
        }
        {
          on = "~";
          run = "help";
          desc = "Open help";
        }
        {
          on = "<F1>";
          run = "help";
          desc = "Open help";
        }
      ];
      prepend_keymap = [
        {
          on = ["g" "i"];
          run = "plugin lazygit";
          desc = "run lazygit";
        }
        {
          on = "l";
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }
      ];
    };

    # [yaziPlugins - MyNixOS](https://mynixos.com/nixpkgs/packages/yaziPlugins)
    plugins = {
      inherit (pkgs.yaziPlugins) lazygit;
      inherit (pkgs.yaziPlugins) full-border;
      inherit (pkgs.yaziPlugins) git;
      inherit (pkgs.yaziPlugins) smart-enter;
      # used to preview archive
      inherit (pkgs.yaziPlugins) ouch;
    };

    initLua = ''
      require("full-border"):setup()
      require("git"):setup()
      require("smart-enter"):setup {
       open_multi = true,
      }
    '';
  };

  # alacritty support for yazi
  # https://yazi-rs.github.io/docs/image-preview/
  # 用imv不支持上下键切换图片，所以处理成yazi内嵌图片preview
  # 而 alacritty 没有内置images render，所以需要ueberzugpp
  home.packages = with pkgs; [ueberzugpp];
}
