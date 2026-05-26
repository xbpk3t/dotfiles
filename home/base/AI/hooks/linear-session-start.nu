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

def issue-from-text [text: string]: nothing -> string {
    let keys = (
        $text
        | parse -r '(?i)(LUC-\d+)'
        | get capture0?
        | default []
        | each {|key| $key | str upcase }
        | uniq
    )

    # Avoid guessing if one context accidentally mentions multiple Linear issues.
    if ($keys | length) == 1 { $keys.0 } else { '' }
}

def read-jj-bookmarks []: nothing -> string {
    # jj bookmarks usually point at an ancestor of @, not the mutable working-copy
    # commit itself, so look for the nearest bookmarked ancestors. --ignore-working-copy
    # keeps hooks read-only and avoids surprise snapshots during agent lifecycle events.
    try {
        ^jj log --ignore-working-copy -r 'heads(::@ & bookmarks())' --no-graph --template 'bookmarks ++ "\n"' err> /dev/null
    } catch { '' } | str trim
}

def issue-from-context [branch: string]: nothing -> string {
    let branch_issue = if ($branch | is-empty) or $branch == 'HEAD' {
        ''
    } else {
        issue-from-text $branch
    }

    if not ($branch_issue | is-empty) {
        $branch_issue
    } else {
        issue-from-text (read-jj-bookmarks)
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

let issue_key = (issue-from-context $branch)

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
