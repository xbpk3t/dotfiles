#!/usr/bin/env -S nu --stdin

# Manual helper: post the latest selected agent response or explicit note to
# the Linear issue linked by the current branch.

let piped_body = ($in | default '' | into string | str trim)

def read-env [name: string, fallback: string = '']: nothing -> string {
    let value = ($env | get --optional $name)
    if $value == null { $fallback } else { $value | into string }
}

def read-file-if-exists [path: string]: nothing -> string {
    if ($path | is-empty) or (not ($path | path exists)) {
        ''
    } else {
        open --raw $path | into string | str trim
    }
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

def log-hook-error [event: string, issue_key: string, message: string]: nothing -> nothing {
    let now = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_file = (read-env 'LINEAR_HOOK_LOG' '/tmp/linear-agent-hooks.log')
    let clean_message = ($message | str trim | str replace --all "\n" ' ')
    do -i { $"($now)\t($event)\tissue=($issue_key)\t($clean_message)\n" | save --append $log_file }
}

def post-linear-comment [
    issue_key: string
    body: string
    event: string
    --stderr-prefix: string = ''
]: nothing -> int {
    let result = (try {
        ^linear issues comment $issue_key --body $body | complete
    } catch {|err|
        {
            exit_code: 127
            stderr: ($err.msg? | default 'linear command failed')
            stdout: ''
        }
    })

    if $result.exit_code != 0 {
        let stderr = ($result.stderr | default '' | str trim)
        let message = if ($stderr | is-empty) { $'linear exited with code ($result.exit_code)' } else { $stderr }
        log-hook-error $event $issue_key $message

        if not ($stderr_prefix | str trim | is-empty) {
            print --stderr $'($stderr_prefix): ($message)'
        }
    }

    $result.exit_code
}

let cwd = (read-env 'LINEAR_LATEST_POST_CWD' '')
if (not ($cwd | is-empty)) and ($cwd | path exists) {
    cd $cwd
}

let branch = (read-current-branch)
let issue_key = if (not (read-env 'LINEAR_LATEST_POST_ISSUE' '' | is-empty)) {
    read-env 'LINEAR_LATEST_POST_ISSUE' '' | str upcase
} else if (not ($env.CLAUDE_LINEAR_ISSUE? | default '' | is-empty)) {
    $env.CLAUDE_LINEAR_ISSUE? | str upcase
} else {
    issue-from-context $branch
}

if ($issue_key | is-empty) {
    print --stderr 'linear-latest-post: no Linear issue key found. Pass --issue LUC-XXX, run on a luc/LUC-XXX branch, or use a jj bookmark containing LUC-XXX.'
    exit 1
}

let body_file = (read-env 'LINEAR_LATEST_POST_BODY_FILE' '')
let env_body = (read-env 'LINEAR_LATEST_POST_BODY' '')
let latest_body = if (not ($body_file | is-empty)) {
    read-file-if-exists $body_file
} else if (not ($env_body | str trim | is-empty)) {
    $env_body | str trim
} else {
    $piped_body
}

if ($latest_body | str trim | is-empty) {
    print --stderr 'linear-latest-post: empty body. Pass content, pipe stdin, or use --body-file.'
    exit 1
}

let now = (date now | format date '%Y-%m-%d %H:%M')
let agent = (read-env 'LINEAR_LATEST_POST_AGENT' (read-env 'LINEAR_AGENT' 'agent'))
let model = (read-env 'LINEAR_LATEST_POST_MODEL' (read-env 'LINEAR_MODEL' 'unknown'))
let session_id = (read-env 'LINEAR_LATEST_POST_SESSION_ID' (read-env 'LINEAR_SESSION_ID' 'unknown'))
let dry_run = (read-env 'LINEAR_LATEST_POST_DRY_RUN' '0') == '1'

let comment = $"**Agent Note** -- ($issue_key)\n\nMetadata:\n- agent: ($agent)\n- model: ($model)\n- session_id: ($session_id)\n- cwd: (pwd)\n- branch: ($branch)\n- source: manual-latest-post\n- generated_at: ($now)\n\n## Note\n\n($latest_body | str trim)\n"

if $dry_run {
    print $comment
    exit 0
}

let exit_code = (post-linear-comment $issue_key $comment 'latest-post-comment' --stderr-prefix 'linear-latest-post')
exit $exit_code
