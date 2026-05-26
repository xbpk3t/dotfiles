#!/usr/bin/env -S nu --stdin

# Explicit finalizer for Linear issue retrospectives.
# The agent generates the review body; this script adds metadata and git facts,
# then posts one final comment to the linked Linear issue.

# Nushell 0.112.2 loses sourced stdin if custom commands are defined first.
let piped_review_body = ($in | default '' | into string | str trim)

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

def section [title: string, body: string]: nothing -> string {
    if ($body | str trim | is-empty) {
        ''
    } else {
        $"\n## ($title)\n\n($body | str trim)\n"
    }
}

let cwd = (read-env 'LINEAR_FINALIZE_CWD' '')
if (not ($cwd | is-empty)) and ($cwd | path exists) {
    cd $cwd
}

let branch = (read-current-branch)
let issue_key = if (not (read-env 'LINEAR_FINALIZE_ISSUE' '' | is-empty)) {
    read-env 'LINEAR_FINALIZE_ISSUE' '' | str upcase
} else {
    issue-from-context $branch
}

if ($issue_key | is-empty) {
    print --stderr 'linear-finalize: no Linear issue key found. Pass --issue LUC-XXX, run on a luc/LUC-XXX branch, or use a jj bookmark containing LUC-XXX.'
    exit 1
}

let now = (date now | format date '%Y-%m-%d %H:%M')
let agent = (read-env 'LINEAR_FINALIZE_AGENT' (read-env 'LINEAR_AGENT' 'agent'))
let model = (read-env 'LINEAR_FINALIZE_MODEL' (read-env 'LINEAR_MODEL' 'unknown'))
let session_id = (read-env 'LINEAR_FINALIZE_SESSION_ID' (read-env 'LINEAR_SESSION_ID' 'unknown'))
let transcript_path = (read-env 'LINEAR_FINALIZE_TRANSCRIPT_PATH' '')
let body_file = (read-env 'LINEAR_FINALIZE_BODY_FILE' '')
let base_ref = (read-env 'LINEAR_FINALIZE_BASE' 'origin/main')
let dry_run = (read-env 'LINEAR_FINALIZE_DRY_RUN' '0') == '1'
let keep_checkpoints = (read-env 'LINEAR_FINALIZE_KEEP_CHECKPOINTS' '0') == '1'

let review_body = if (not ($body_file | is-empty)) {
    read-file-if-exists $body_file
} else {
    $piped_review_body
}

let plan_file = $"/tmp/linear-session-plan-($issue_key).md"
let finalized_marker_file = $"/tmp/linear-session-finalized-($issue_key)"

let captured_plans = (read-file-if-exists $plan_file)

let commits = (try { ^git log $"($base_ref)..HEAD" --oneline err> /dev/null } catch { '' } | str trim)
let diff_stat = (try { ^git diff HEAD --stat err> /dev/null } catch { '' } | str trim)
let status = (try { ^git status --short err> /dev/null } catch { '' } | str trim)

let review_section = if ($review_body | is-empty) {
    "\n## Agent Review\n\n_No review body was provided. This is a facts-only finalization._\n"
} else {
    section 'Agent Review' $review_body
}

let plans_section = section 'Captured Plans' $captured_plans

let commits_section = if ($commits | is-empty) {
    ''
} else {
    $"### Commits since ($base_ref)\n```text\n($commits)\n```\n\n"
}

let diff_section = if ($diff_stat | is-empty) {
    ''
} else {
    $"### Uncommitted changes\n```text\n($diff_stat)\n```\n\n"
}

let status_section = if ($status | is-empty) {
    ''
} else {
    $"### Git status\n```text\n($status)\n```\n\n"
}

let git_section_body = $"($commits_section)($diff_section)($status_section)"
let git_section = section 'Git Facts' $git_section_body

let comment = $"**Agent Review** -- ($issue_key)\n\nMetadata:\n- agent: ($agent)\n- model: ($model)\n- session_id: ($session_id)\n- cwd: (pwd)\n- branch: ($branch)\n- transcript_path: ($transcript_path)\n- trigger: manual-finalize\n- generated_at: ($now)\n($review_section)($plans_section)($git_section)"

if $dry_run {
    print $comment
    exit 0
}

let exit_code = (post-linear-comment $issue_key $comment 'finalize-comment' --stderr-prefix 'linear-finalize')
if $exit_code != 0 {
    exit $exit_code
}

if (not $keep_checkpoints) {
    do -i { $now | save --force $finalized_marker_file }
    if ($plan_file | path exists) { do -i { rm $plan_file } }
}
