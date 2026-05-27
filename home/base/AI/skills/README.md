# AI Skills Design Notes

This directory contains local agent skills and supporting scripts. A skill folder should keep execution instructions in `SKILL.md`; scripts belong under `scripts/` when deterministic behavior is useful.

## README Placement

Do not add a per-skill `README.md` for normal workflow notes. Skill runners discover skills from `SKILL.md`, and extra docs inside a skill folder create maintenance ambiguity even when they are not automatically loaded into context. Use this directory-level README for design decisions that should survive later refactors.

Third-party or imported skills may include their own README files. Treat those as upstream documentation, not the preferred pattern for new local workflow skills.

## Linear Note Direction

`linear-note` is the single local entry point for posting agent notes and final issue reviews to Linear.

Design decisions:

- Use a skill-first workflow, not lifecycle hooks.
- Keep Nix involvement minimal: install/copy the skill and helper scripts, but do not wire automatic session hooks.
- Keep `SKILL.md` as the semantic entry and usage guide.
- Keep Nushell helpers deterministic: build metadata, detect issue keys, add git facts, and publish comments.
- Feed note/review bodies through stdin so large Markdown bodies do not depend on shell argument length or escaping.

## Session-History Reviews

For Claude Code final reviews, prefer session-history evidence over memory-only retrospectives, but keep the workflow intentionally lightweight.

The intended flow is:

1. Use `cc2md list --json` to choose one explicit Claude Code main session.
2. Export that session to `/tmp` as Markdown.
3. Have the agent read the artifact and write an execution-timeline review: what happened, key pivots, decisions, implementation, verification, and risks.
4. Dry-run the Linear comment.
5. Post the final review with `linear-note end`.

If clear-context or plan/execution splitting may have happened, list a few recent same-project sessions and recent plan files as candidates. Do not build an interactive picker or infer a canonical multi-session graph. If planning evidence is missing, say so in the final review.

The exported transcript is source material, not the default Linear comment body. Do not paste full transcripts into Linear unless explicitly requested for a specific issue.

## Boundaries

- `cc2md` is an optional prerequisite for Claude Code session-history reviews; it is not installed by this skill.
- The current design targets one Claude Code main session by default. It does not solve Codex, subagent, or agent-team transcript stitching.
- `linear-note` is not an agent observability system. A future multi-agent session graph should be a separate tool, not hidden in this skill.
- `/tmp` session artifacts are temporary working files and should not be committed.
- Do not post private chain-of-thought or thinking blocks. Use `cc2md --thinking` only after explicit user approval.
