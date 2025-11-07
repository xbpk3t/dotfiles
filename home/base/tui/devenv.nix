# {pkgs, config, ...}: {
#   name = "dotfiles";
#
#   env = {
#     RUST_BACKTRACE = "1";
#     RUST_LOG = "info";
#     NIXPKGS_ALLOW_UNFREE = "1";
#     EDITOR = "nvim";
#   };
#
#   # dotenv.enable = true;
#
#   packages = with pkgs; [
#     git
#     gitFull
#     jq
#     nixpkgs-fmt
#     alejandra
#     treefmt
#     direnv
#     devenv
#     nil
#     statix
#     cargo-watch
#     gofumpt
#     python311Packages.debugpy
#     nodePackages.typescript-language-server
#   ];
#
#   languages = {
#     nix.enable = true;
#
#     rust = {
#       enable = true;
#       channel = "stable";
#       components = ["cargo" "clippy" "rust-analyzer" "rustfmt"];
#       targets = ["wasm32-unknown-unknown"];
#     };
#
#     javascript = {
#       enable = true;
#       package = pkgs.nodejs_22_x;
#       corepack.enable = true;
#       npm.enable = true;
#       pnpm.enable = true;
#       yarn.enable = true;
#       bun = {
#         enable = true;
#         install.enable = true;
#       };
#     };
#
#     python = {
#       enable = true;
#       version = "3.11";
#       venv.enable = true;
#       uv.enable = true;
#       poetry.enable = true;
#     };
#
#     go = {
#       enable = true;
#       package = pkgs.go_1_22;
#     };
#   };
#
#   scripts = {
#     fmt.exec = "treefmt --config-file treefmt.toml";
#     lint.exec = "devenv shell treefmt --config-file treefmt.ci.toml";
#   };
#
#   tasks = {
#     "chore:lint" = {
#       description = "Lint the code";
#       exec = "treefmt --config-file treefmt.toml";
#     };
#
#     "ci:lint" = {
#       description = "CI lint with stricter config";
#       exec = "devenv shell treefmt --config-file treefmt.ci.toml";
#     };
#   };
#
#   git-hooks = {
#     hooks = {
#       commitizen = {
#         enable = true;
#         stages = ["commit-msg"];
#       };
#       lint = {
#         enable = true;
#         stages = ["pre-commit"];
#         name = "lint";
#         description = "Lint the code";
#         pass_filenames = true;
#         entry = "treefmt --config-file treefmt.toml";
#       };
#     };
#   };
#
#   services = {
#     postgres = {
#       enable = true;
#       package = pkgs.postgresql_16;
#       initialDatabases = [{name = "app";}];
#       settings.port = 5432;
#     };
#     redis = {
#       enable = true;
#       port = 6379;
#     };
#   };
#
#   processes = {
#     devserver.exec = "npm run dev -- --host";
#     api.exec = "cargo watch -x run";
#   };
#
#   #enterShell = ''
#   #  echo "devenv · dotfiles"
#   #  git status -sb || true
#   #'';
# }
_: {}
