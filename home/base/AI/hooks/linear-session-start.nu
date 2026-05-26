#!/usr/bin/env -S nu --stdin

# SessionStart hook: detect Linear issue key (LUC-XXX) from git branch
# and export it to CLAUDE_ENV_FILE for downstream hooks.

let input = ($in | from json)
let cwd = ($input.cwd? | default '')

if ($cwd | is-empty) {
    exit 0
}

if (not ($cwd | path exists)) {
    exit 0
}

cd $cwd

let branch = (try { ^git rev-parse --abbrev-ref HEAD err> /dev/null } catch { '' } | str trim)

if ($branch | is-empty) or $branch == 'HEAD' {
    exit 0
}

let issue_key = ($branch | parse -r '(?i)(LUC-\d+)' | get 0.capture0?)

if ($issue_key == null) {
    exit 0
}

let env_file = ($env.CLAUDE_ENV_FILE? | default '')

if ($env_file | is-empty) {
    exit 0
}

do -i {
    $"export CLAUDE_LINEAR_ISSUE=($issue_key | str upcase)\n" | save --append $env_file
}
