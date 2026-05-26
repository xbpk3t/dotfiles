#!/usr/bin/env -S nu --stdin

# SessionStart hook: detect Linear issue key (LUC-XXX) from git branch
# and export it to CLAUDE_ENV_FILE for downstream hooks.

let input = ($in | from json)

def read-env [name: string, fallback: string = '']: nothing -> string {
    let value = ($env | get --optional $name)
    if $value == null { $fallback } else { $value | into string }
}

def read-current-branch []: nothing -> string {
    try { ^git rev-parse --abbrev-ref HEAD err> /dev/null } catch { '' } | str trim
}

def issue-from-branch [branch: string]: nothing -> string {
    if ($branch | is-empty) or $branch == 'HEAD' {
        ''
    } else {
        let key = ($branch | parse -r '(?i)(LUC-\d+)' | get 0.capture0?)
        if $key == null { '' } else { $key | str upcase }
    }
}

let cwd = ($input.cwd? | default '')

if ($cwd | is-empty) {
    exit 0
}

if (not ($cwd | path exists)) {
    exit 0
}

cd $cwd

let branch = (read-current-branch)

if ($branch | is-empty) or $branch == 'HEAD' {
    exit 0
}

let issue_key = (issue-from-branch $branch)

if ($issue_key | is-empty) {
    exit 0
}

let env_file = (read-env 'CLAUDE_ENV_FILE' '')

if ($env_file | is-empty) {
    exit 0
}

do -i {
    $"export CLAUDE_LINEAR_ISSUE=($issue_key)\n" | save --append $env_file
}
