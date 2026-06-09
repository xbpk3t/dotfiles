# GitHub Repositories Stack

This stack adopts the baseline settings for the core `xbpk3t` repositories that
are tied to this infra repo, Cloudflare Pages, Flux, and personal automation.

## Managed resources

- Repositories: `dotfiles`, `docs`, `zzz`, `me`, `wiki`, `quant`
- Repository settings and topics, matching the current live baseline
- Actions repository permissions and default `GITHUB_TOKEN` workflow permissions
- Existing environments: `docs:docs (Production)` and `zzz:production`
- Existing read-only Flux deploy keys on `dotfiles`
- Lightweight protection for public `dotfiles/main`

Private repository branch protection is intentionally not managed in this stack.
GitHub currently returns a paid-plan gate for private repo branch protection and
repository rulesets on this account.

## Secrets policy

Actions secret values are not managed by Terraform. The names are kept as
inventory only in `locals.secret_inventory` so ownership is visible without
putting secret material into Terraform state.

Current inventory:

- `docs`: `CF_ACCOUNT_ID`, `CF_API_TOKEN`, `EXA_API_KEY`, `PAT`,
  `QUANT_SYNC_TOKEN`, `R2_ACCOUNT`, `R2_AK`, `R2_KEY`, `RESEND_TOKEN`,
  `TAVILY_API_KEY`, `TOKEN`
- `zzz`: `CF_ACCOUNT_ID`, `CF_API_TOKEN`
- `me`: `CF_ACCOUNT_ID`, `CF_API_TOKEN`

## Usage

```bash
export GITHUB_TOKEN="..."
export CF_R2_AK="..."
export CF_R2_SK="..."

task tf:validate STACK=infra/stacks/homelab/github/repositories
task tf:plan STACK=infra/stacks/homelab/github/repositories
```

The S3-compatible backend still reads `AWS_*` internally, but the repo Taskfile
maps `CF_R2_AK` and `CF_R2_SK` to those names for normal use.

Expected first apply shape:

- Import existing repository, Actions permission, workflow permission,
  environment, and deploy key resources
- Create only `github_branch_protection.dotfiles_main`
- Do not create any `github_actions_secret` resources
