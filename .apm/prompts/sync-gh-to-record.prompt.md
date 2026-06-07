---
description: Sync dotfiles GitHub-backed changes into docs data/gh records
---

Sync GitHub-backed changes from this dotfiles repo into docs `data/gh` records.

Repositories:
- Dotfiles: `~/Desktop/docs/dotfiles`
- Docs: `~/Desktop/docs`

Use this workflow:

1. Inspect changed dotfiles paths:

```bash
docs-cli dotfiles sync-record --path ~/Desktop/docs/dotfiles --format json
```

2. For each relevant changed file, inspect the diff before deciding anything:

```bash
git -C ~/Desktop/docs/dotfiles diff -- <changed-file>
```

3. Extract only explicit GitHub repository signals from the diff or nearby config:
- `https://github.com/<owner>/<repo>`
- `github:<owner>/<repo>`, normalized to `https://github.com/<owner>/<repo>`
- comments next to Docker images or package definitions that directly name a GitHub repo

Do not infer a GitHub URL from an image name, package name, service name, or homepage unless the diff or existing docs record confirms it.

4. Verify each candidate against existing docs records:

```bash
data-cli gh find <url-or-owner/repo>
```

5. Append a record only when there is exactly one clear existing `data/gh` entry:

```bash
data-cli gh append-record --url <url> --des "<short factual description>"
```

Do not pass `--date` unless the user explicitly asks for a historical date. The command defaults to today.

6. Keep descriptions short and factual. Prefer describing what changed in dotfiles, for example:
- `Add treefmt-nix flake input`
- `Enable wud compose service`
- `Update package source configuration`

7. If the URL, target record, or description is ambiguous, do not append. Report pending confirmations with the changed file, candidate signal, and question.

8. After appending records, validate:

```bash
data-cli check gh
docs-cli dotfiles check --path ~/Desktop/docs/dotfiles
```

Do not commit, push, deploy, or modify unrelated docs content.
