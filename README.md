# dotfiles

[![flake-check](https://github.com/xbpk3t/dotfiles/actions/workflows/flake-check.yml/badge.svg)](https://github.com/xbpk3t/dotfiles/actions/workflows/flake-check.yml)



---


![topology](./topology.svg)

## Stack

| Layer | Tool |
|---|---|
| Flake framework | [flake-parts](https://github.com/hercules-ci/flake-parts) |
| Systems | [NixOS](https://nixos.org) · [nix-darwin](https://github.com/LnL7/nix-darwin) · [home-manager](https://github.com/nix-community/home-manager) |
| Deploy | [deploy-rs](https://github.com/serokell/deploy-rs) |
| Secrets | [sops-nix](https://github.com/Mic92/sops-nix) |
| Non-NixOS | [system-manager](https://github.com/numtide/system-manager) |
| Pack | [nvfetcher](https://github.com/berberman/nvfetcher) (self-maintained `pkgs/`) |
