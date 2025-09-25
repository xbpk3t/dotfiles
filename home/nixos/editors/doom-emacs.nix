{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      emacs-gtk
      git
      lazygit
      ripgrep
      libtool
      cmake
      pkg-config
      # Spell checking
      hunspell
      hunspellDicts.en_US
      hunspellDicts.en_AU
      hunspellDicts.es_ES
      # LSP servers
      clang-tools # C/C++ LSP
      nil # Nix LSP
    ];

    file = {
      ".doom.d/init.el".text = ''
        ;;; init.el -*- lexical-binding: t; -*-

        (doom!
         :completion
         (company +auto)
         (vertico +icons)

         :ui
         doom
         doom-dashboard
         doom-quit
         hl-todo
         modeline
         nav-flash
         ophints
         (popup +defaults)
         (ligatures +extra)
         tabs
         treemacs
         vi-tilde-fringe
         window-select

         :editor
         (evil +everywhere)
         file-templates
         fold
         multiple-cursors
         snippets
         word-wrap

         :emacs
         (dired +icons)
         electric
         (ibuffer +icons)
         (undo +tree)
         vc

         :term
         vterm

         :checkers
         (syntax +flymake)
         (spell +flyspell)
         grammar

         :tools
         (eval +overlay)
         (lookup +docsets)
         lsp
         (magit +forge)
         pdf
         tree-sitter

         :lang
         bash
         (c +lsp)
         css
         docker
         html
         (json +lsp)
         markdown
         (nix +tree-sitter +lsp)
         toml
         yaml

         :config
         (default +bindings +smartparens))
      '';

      ".doom.d/config.el".text = ''
        ;;; config.el -*- lexical-binding: t; -*-

        (setq doom-theme 'doom-one)
        (setq display-line-numbers-type 'relative)
        (setq nerd-icons-font-family "JetBrainsMono Nerd Font")

        ;; Git configuration
        (after! magit
          ;; Set default git editor to emacsclient
          (setq with-editor-emacsclient-executable "emacsclient")
          ;; Show word-granularity differences within diff hunks
          (setq magit-diff-refine-hunk t)
          ;; Auto-refresh magit buffers
          (setq magit-refresh-status-buffer t))

        ;; Lazygit integration
        (defun my/lazygit ()
          "Open lazygit in a terminal."
          (interactive)
          (if (fboundp 'vterm)
              (let ((default-directory (magit-toplevel)))
                (vterm "*lazygit*")
                (vterm-send-string "lazygit")
                (vterm-send-return))
            (async-shell-command "lazygit" "*lazygit*")))

        ;; LSP configuration
        (after! lsp-mode
          (setq lsp-signature-auto-activate t
                lsp-signature-render-documentation t
                lsp-completion-provider :company-capf
                lsp-idle-delay 0.1))

        ;; Nix LSP (nil) configuration
        (with-eval-after-load 'lsp-nix-nil
          (setq lsp-nix-nil-auto-eval-inputs t))

        ;; Company completion settings
        (after! company
          (setq company-idle-delay 0.2
                company-minimum-prefix-length 1
                company-tooltip-align-annotations t
                company-require-match 'never))

        ;; Spell checking configuration
        (after! ispell
          (setq ispell-program-name "hunspell")
          (setq ispell-local-dictionary "en_US")
          (setq ispell-local-dictionary-alist
                '(("en_US" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil ("-d" "en_US") nil utf-8))))

        ;; Git keybindings
        (map! :leader
              (:prefix-map ("g" . "git")
               :desc "Magit status" "g" #'magit-status
               :desc "Magit dispatch" "d" #'magit-dispatch
               :desc "Magit file dispatch" "f" #'magit-file-dispatch
               :desc "Magit blame" "b" #'magit-blame-addition
               :desc "Git time machine" "t" #'git-timemachine-toggle
               :desc "Lazygit" "l" #'my/lazygit
               :desc "Git stage file" "s" #'magit-stage-file
               :desc "Git unstage file" "u" #'magit-unstage-file))
      '';

      ".doom.d/packages.el".text = ''
        ;;; packages.el -*- lexical-binding: t; -*-

        ;; Git-related packages
        (package! git-timemachine)
      '';
    };
  };
}
