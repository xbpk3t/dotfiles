{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
with lib;
let
  inherit (inputs.nvf.lib.nvim.dag) entryAfter;
  cfg = config.modules.tui.nvim;
in
{
  options.modules.tui.nvim = {
    enable = lib.mkEnableOption "Enable NVF (for Vim)";
  };

  config = mkIf cfg.enable {
    home.file.".config/nvf/lua" = {
      source = ./lua;
      recursive = true;
    };

    programs.nvf = {
      enable = true;

      settings.vim = {
        vimAlias = true;
        viAlias = true;

        options = {
          tabstop = 2;
          shiftwidth = 2;
          number = true;
          relativenumber = false;
          clipboard = "unnamedplus";
          wrap = true;
          linebreak = true;
          breakindent = true;
          completeopt = "menu,menuone,noinsert,noselect";
        };

        keymaps = [
          # ── Insert Mode ──────────────────────────
          {
            key = "jk";
            mode = [ "i" ];
            action = "<ESC>";
            desc = "Exit insert mode";
          }
          {
            key = "<C-h>";
            mode = [ "i" ];
            action = "<Left>";
            desc = "Move left in insert mode";
          }
          {
            key = "<C-j>";
            mode = [ "i" ];
            action = "<Down>";
            desc = "Move down in insert mode";
          }
          {
            key = "<C-k>";
            mode = [ "i" ];
            action = "<Up>";
            desc = "Move up in insert mode";
          }
          {
            key = "<C-l>";
            mode = [ "i" ];
            action = "<Right>";
            desc = "Move right in insert mode";
          }

          # ── Files (<leader>f) ────────────────────
          {
            key = "<leader>ff";
            mode = [ "n" ];
            action = "<cmd>Telescope find_files<cr>";
            desc = "Find files";
          }
          {
            key = "<leader>fg";
            mode = [ "n" ];
            action = "<cmd>Telescope live_grep<cr>";
            desc = "Live grep";
          }
          {
            key = "<leader>fr";
            mode = [ "n" ];
            action = "<cmd>lua __nvf_open_oldfiles()<cr>";
            desc = "Recent files";
          }
          {
            key = "<leader>fd";
            mode = [ "n" ];
            action = "<cmd>DeleteCurrentFile<cr>";
            desc = "Delete file";
          }

          {
            key = "<leader>fs";
            mode = [ "n" ];
            action = "<cmd>lua __nvf_lsp_document_symbols()<cr>";
            desc = "Document symbols";
          }

          # ── Buffer (<leader>b) ───────────────────
          {
            key = "<leader>bn";
            mode = [ "n" ];
            action = "<cmd>bnext<cr>";
            desc = "Next buffer";
          }
          {
            key = "<leader>bp";
            mode = [ "n" ];
            action = "<cmd>bprevious<cr>";
            desc = "Previous buffer";
          }
          {
            key = "<leader>bd";
            mode = [ "n" ];
            action = "<cmd>bdelete<cr>";
            desc = "Close buffer";
          }

          # ── LSP ──────────────────────────────────
          {
            key = "gd";
            mode = [ "n" ];
            action = "<cmd>lua vim.lsp.buf.definition()<cr>";
            desc = "Go to definition";
          }
          {
            key = "gD";
            mode = [ "n" ];
            action = "<cmd>lua vim.lsp.buf.declaration()<cr>";
            desc = "Go to declaration";
          }
          {
            key = "gI";
            mode = [ "n" ];
            action = "<cmd>lua vim.lsp.buf.implementation()<cr>";
            desc = "Go to implementation";
          }
          {
            key = "gr";
            mode = [ "n" ];
            action = "<cmd>lua vim.lsp.buf.references()<cr>";
            desc = "List references";
          }
          {
            key = "K";
            mode = [ "n" ];
            action = "<cmd>lua vim.lsp.buf.hover()<cr>";
            desc = "Hover";
          }
          {
            key = "<leader>lr";
            mode = [ "n" ];
            action = "<cmd>lua vim.lsp.buf.rename()<cr>";
            desc = "Rename";
          }
          {
            key = "<leader>la";
            mode = [ "n" ];
            action = "<cmd>lua vim.lsp.buf.code_action()<cr>";
            desc = "Code action";
          }

          # ── Diagnostics ──────────────────────────
          {
            key = "[d";
            mode = [ "n" ];
            action = "<cmd>lua vim.diagnostic.goto_prev()<cr>";
            desc = "Previous diagnostic";
          }
          {
            key = "]d";
            mode = [ "n" ];
            action = "<cmd>lua vim.diagnostic.goto_next()<cr>";
            desc = "Next diagnostic";
          }

          # ── Misc ─────────────────────────────────
          {
            key = "<leader>nh";
            mode = [ "n" ];
            action = ":nohl<CR>";
            desc = "Clear highlights";
          }
          {
            key = "<leader>ua";
            mode = [ "n" ];
            action = "<cmd>ASToggle<cr>";
            desc = "Toggle auto-save";
          }
          {
            key = "ss";
            mode = [ "n" ];
            action = "\"_dd";
            desc = "Delete without yank";
          }
          {
            key = "<leader>q";
            mode = [ "n" ];
            action = "<cmd>qa<CR>";
            desc = "Quit";
          }
          {
            key = "<leader>Q";
            mode = [ "n" ];
            action = "<cmd>qa!<CR>";
            desc = "Force quit";
          }
        ];

        telescope.enable = true;

        spellcheck = {
          enable = false;
        };

        lsp = {
          enable = true;
          formatOnSave = true;
          lspkind.enable = false;
          lightbulb.enable = true;
          lspsaga.enable = false;
          trouble.enable = true;
          lspSignature.enable = true;
          otter-nvim.enable = false;
          nvim-docs-view.enable = false;
        };

        languages = {
          enableFormat = true;
          enableTreesitter = true;
          enableExtraDiagnostics = true;

          nix = {
            enable = true;
            format.type = [ "nixfmt" ];
          };
          go.enable = true;
          rust.enable = true;
          zig.enable = true;
          lua.enable = true;
          clang.enable = true;
          python.enable = true;
          markdown.enable = true;
          typescript.enable = true;
          html.enable = true;
          yaml.enable = true;
          bash.enable = true;
          docker.enable = true;
          terraform.enable = true;
          helm.enable = true;
          tex.enable = true;
          toml.enable = true;
        };

        visuals = {
          nvim-web-devicons.enable = true;
          nvim-cursorline.enable = true;
          cinnamon-nvim.enable = false;
          fidget-nvim.enable = true;
          highlight-undo.enable = false;
          indent-blankline.enable = true;
        };

        autopairs.nvim-autopairs.enable = false;

        autocomplete.nvim-cmp.enable = false;

        snippets.luasnip.enable = false;

        tabline = {
          nvimBufferline.enable = false;
        };

        treesitter.context.enable = false;

        binds = {
          whichKey.enable = true;
          cheatsheet.enable = true;
        };

        git = {
          enable = true;
          gitsigns.enable = true;
          gitsigns.codeActions.enable = false;
        };

        projects.project-nvim.enable = false;

        dashboard.dashboard-nvim.enable = false;

        filetree.neo-tree.enable = false;

        notify = {
          nvim-notify.enable = false;
          nvim-notify.setupOpts.background_colour = "#f38ba8";
        };

        utility = {
          ccc.enable = false;
          vim-wakatime.enable = false;
          icon-picker.enable = false;
          surround.enable = false;
          diffview-nvim.enable = true;

          motion = {
            flash-nvim.enable = true;
            precognition.enable = false;
          };

          images = {
            image-nvim.enable = false;
          };
        };

        ui = {
          borders.enable = true;
          noice.enable = false;
          colorizer.enable = true;
          illuminate.enable = true;

          breadcrumbs = {
            enable = true;
            navbuddy.enable = true;
          };

          smartcolumn = {
            enable = true;
          };

          fastaction.enable = true;
        };

        session = {
          nvim-session-manager.enable = false;
        };

        comments = {
          comment-nvim.enable = true;
        };

        lazy = {
          plugins = with pkgs.vimPlugins; {
            "monokai-pro.nvim" = {
              package = monokai-pro-nvim;
              lazy = false;
              priority = 1000;
              after = ''require("config.monokai").setup()'';
            };
            "auto-save.nvim" = {
              package = auto-save-nvim;
              lazy = false;
              after = ''
                require("auto-save").setup({})
              '';
            };

            "vim-dadbod-ui" = {
              package = vim-dadbod-ui;
              cmd = [
                "DBUI"
                "DBUIToggle"
              ];
              keys = [
                {
                  key = "<leader>D";
                  mode = [ "n" ];
                  action = ":DBUIToggle<CR>";
                  desc = "Toggle Database UI";
                }
              ];
              after = ''
                vim.g.db_ui_use_nerd_fonts = 1
                vim.g.db_ui_show_database_icon = 1
              '';
            };

            "nvim-surround" = {
              package = nvim-surround;
              event = [
                {
                  event = "User";
                  pattern = "LazyFile";
                }
              ];
              after = ''
                require("nvim-surround").setup({})
              '';
            };

            "nvim-autopairs" = {
              package = nvim-autopairs;
              event = [ "InsertEnter" ];
              after = ''require("config.autopairs").setup()'';
            };
            "yazi.nvim" = {
              package = pkgs.vimPlugins."yazi-nvim";
              cmd = [ "Yazi" ];
              keys = [
                {
                  key = "<leader>fe";
                  mode = [ "n" ];
                  action = ":lua YaziProjectRoot()<CR>";
                  desc = "Explorer (yazi)";
                }
              ];
              after = ''
                require("yazi").setup({
                  open_for_directories = false,
                  open_multiple_tabs = false,
                  floating_window_scaling_factor = 0.92,
                  change_neovim_cwd_on_close = false,
                  highlight_hovered_buffers_in_same_directory = true,
                  future_features = { use_cwd_file = false },
                })
              '';
            };
          };
        };

        luaConfigRC = {
          delete-current-file = ''require("config.delete-file").setup()'';
          telescope-helpers = ''require("config.telescope-helpers").setup()'';
          telescope-setup = entryAfter [ "pluginConfigs" ] ''require("config.telescope").setup()'';
          yazi-project = ''require("config.yazi").setup()'';
        };
      };
    };
  };
}
