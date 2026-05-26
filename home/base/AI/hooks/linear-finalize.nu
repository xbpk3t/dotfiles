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

def issue-from-branch [branch: string]: nothing -> string {
    if ($branch | is-empty) or $branch == 'HEAD' {
        ''
    } else {
        let key = ($branch | parse -r '(?i)(LUC-\d+)' | get 0.capture0?)
        if $key == null { '' } else { $key | str upcase }
    }
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

let branch = (try { ^git rev-parse --abbrev-ref HEAD err> /dev/null } catch { '' } | str trim)
let issue_key = if (not (read-env 'LINEAR_FINALIZE_ISSUE' '' | is-empty)) {
    read-env 'LINEAR_FINALIZE_ISSUE' '' | str upcase
} else {
    issue-from-branch $branch
}

if ($issue_key | is-empty) {
    print --stderr 'linear-finalize: no Linear issue key found. Pass --issue LUC-XXX or run on a luc/LUC-XXX branch.'
    exit 1
}

let now = (date now | format date '%Y-%m-%d %H:%M')
let agent = (read-env 'LINEAR_FINALIZE_AGENT' 'agent')
let model = (read-env 'LINEAR_FINALIZE_MODEL' 'unknown')
let session_id = (read-env 'LINEAR_FINALIZE_SESSION_ID' 'unknown')
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
let notes_file = $"/tmp/linear-session-notes-($issue_key).md"
let legacy_notes_file = '/tmp/linear-session-notes.md'
let finalized_marker_file = $"/tmp/linear-session-finalized-($issue_key)"

let captured_plans = (read-file-if-exists $plan_file)
let session_notes = (read-file-if-exists $notes_file)
let legacy_session_notes = if ($session_notes | is-empty) {
    read-file-if-exists $legacy_notes_file
} else {
    ''
}

let commits = (try { ^git log $"($base_ref)..HEAD" --oneline err> /dev/null } catch { '' } | str trim)
let diff_stat = (try { ^git diff HEAD --stat err> /dev/null } catch { '' } | str trim)
let status = (try { ^git status --short err> /dev/null } catch { '' } | str trim)

let review_section = if ($review_body | is-empty) {
    "\n## Agent Review\n\n_No review body was provided. This is a facts-only finalization._\n"
} else {
    section 'Agent Review' $review_body
}

let plans_section = section 'Captured Plans' $captured_plans
let notes_body = ([$session_notes $legacy_session_notes] | where {|note| not ($note | is-empty) } | str join "\n\n")
let notes_section = section 'Session Notes' $notes_body

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

let comment = $"**Agent Review** -- ($issue_key)\n\nMetadata:\n- agent: ($agent)\n- model: ($model)\n- session_id: ($session_id)\n- cwd: (pwd)\n- branch: ($branch)\n- transcript_path: ($transcript_path)\n- trigger: manual-finalize\n- generated_at: ($now)\n($review_section)($plans_section)($notes_section)($git_section)"

if $dry_run {
    print $comment
    exit 0
}

^linear issues comment $issue_key --body $comment

if (not $keep_checkpoints) {
    do -i { $now | save --force $finalized_marker_file }
    if ($plan_file | path exists) { do -i { rm $plan_file } }
    if ($notes_file | path exists) { do -i { rm $notes_file } }
    if (($session_notes | is-empty) and (not ($legacy_session_notes | is-empty)) and ($legacy_notes_file | path exists)) {
        do -i { rm $legacy_notes_file }
    }
}
