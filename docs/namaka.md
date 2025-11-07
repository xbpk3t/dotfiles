# Namaka Snapshot Tests

## Overview

Namaka is a snapshot-testing harness for Nix that builds on top of Haumea to load test trees and compare their serialized output against tracked snapshots, which makes it ideal for validating structured flakes like this dotfiles repo.citeturn0search2

## Repository Layout

- `tests/haumea/expr.nix` evaluates the Haumea fixtures and returns the normalized data we want to pin.
- `fixtures/haumea/{linux,darwin}` contain lightweight host/module descriptions that mirror the real machines without needing to evaluate the entire system.
- `tests/_snapshots/haumea` stores the approved snapshot; Namaka writes pending updates to `tests/_snapshots/.pending/` before you accept them.
- `namaka.toml` pins the command to `nix eval .#checks`, so running the suite does not rebuild every other flake output.citeturn1search1

## Running the Checks

1. Ensure you are in the flake root (`/home/luck/Desktop/dotfiles`) and have a recent `nix develop` shell if needed.
2. Run `namaka check`. The command executes `nix eval .#checks`, evaluates `tests/haumea/expr.nix`, and drops any mismatches into `tests/_snapshots/.pending/`.
3. When everything matches the stored snapshot you will see `✔ haumea` and the process exits with status 0.

## Reviewing & Accepting Changes

1. After modifying fixtures or Haumea-related code, run `namaka check`; it will fail and create a pending snapshot if the serialized value changed.
2. Run `namaka review` to launch the interactive diff viewer. Use the arrow keys (or the on-screen prompt) to choose **accept**, **reject**, or **skip**, then press Enter. Accepted files are moved from `_snapshots/.pending/` into `_snapshots/` so future checks pass.citeturn1search0
3. Re-run `namaka check` to confirm the suite is green.

> Tip: if you cannot use the interactive reviewer (e.g., inside a non-TTY CI step), you can manually move the files from `_snapshots/.pending/` into `_snapshots/` after inspecting them, which mimics the accept path.

## Updating or Extending Tests

- Add a new folder under `tests/` (for example `tests/haumea-linux`) with its own `expr.nix` if you want to snapshot a different data set. Keep any helper fixtures in `fixtures/` (or another directory outside `tests/`) so Haumea does not try to treat them as tests.
- Expose any required inputs via `outputs/default.nix` → `checks = inputs.namaka.lib.load { ... }`. Today we pass `lib`, `haumea`, and a default `pkgs` instance for convenience.
- Keep snapshots under version control; Namaka relies on Git-tracked `_snapshots/*` to make the old/new comparison reproducible.
