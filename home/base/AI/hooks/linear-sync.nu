#!/usr/bin/env -S nu --stdin

# SessionEnd hook: post a lightweight checkpoint for Claude Code sessions.
# Final retrospectives are produced explicitly with linear-finalize.
# If an old Codex config still invokes this from Stop, skip it because Codex Stop
# is turn-scoped and would otherwise create repeated Linear comments.

let input = ($in | from json)
let hook_event = ($input.hook_event_name? | default '')

if $hook_event == 'Stop' {
    exit 0
}

let cwd = ($input.cwd? | default '.')
if ($cwd | path exists) {
    cd $cwd
} else {
    exit 0
}

let branch = (try { ^git rev-parse --abbrev-ref HEAD err> /dev/null } catch { '' } | str trim)

# Detect Linear issue key: env first, then git branch (Codex fallback)
let issue_key = if (not ($env.CLAUDE_LINEAR_ISSUE? | default '' | is-empty)) {
    $env.CLAUDE_LINEAR_ISSUE?
} else {
    if ($branch | is-empty) or $branch == 'HEAD' { '' } else {
        let key = ($branch | parse -r '(?i)(LUC-\d+)' | get 0.capture0?)
        if $key == null { '' } else { $key | str upcase }
    }
}

if ($issue_key | is-empty) {
    exit 0
}

# ── Git info ──

let commits = (try { ^git log origin/main..HEAD --oneline err> /dev/null } catch { '' } | str trim)

let diff_stat = (try { ^git diff HEAD --stat err> /dev/null } catch { '' } | str trim)

# ── Session notes (from /linear-note skill) ──

let notes_file = $"/tmp/linear-session-notes-($issue_key).md"
let legacy_notes_file = '/tmp/linear-session-notes.md'

let notes = if ($notes_file | path exists) {
    open --raw $notes_file | into string | str trim
} else if ($legacy_notes_file | path exists) {
    open --raw $legacy_notes_file | into string | str trim
} else {
    ''
}

# ── Insights from transcript ──

let transcript_path = ($input.transcript_path? | default '')

let insights = if ($transcript_path | is-empty) or (not ($transcript_path | path exists)) {
    []
} else {
    try {
        open --raw $transcript_path
        | into string
        | lines
        | where {|line| $line =~ '★ Insight' }
        | each {|line|
            let parsed = (try { $line | from json } catch { null })
            if $parsed == null {
                []
            } else {
                $parsed.message.content?
                | default []
                | where type == 'text'
                | get text?
                | default []
            }
        }
        | flatten
    } catch { [] }
}

# ── Check if anything to report ──

let has_insights = (not ($insights | is-empty))
let has_commits = (not ($commits | is-empty))
let has_stat = (not ($diff_stat | is-empty))
let has_notes = (not ($notes | is-empty))

if (not $has_insights) and (not $has_commits) and (not $has_stat) and (not $has_notes) {
    exit 0
}

# ── Build comment ──

let now = (date now | format date '%Y-%m-%d %H:%M')
let session_id = ($input.session_id? | default 'unknown')
let model = ($input.model? | default 'unknown')
let agent = if (not ($env.CLAUDE_LINEAR_ISSUE? | default '' | is-empty)) or (not ($env.CLAUDE_ENV_FILE? | default '' | is-empty)) {
    'claude-code'
} else if $model != 'unknown' {
    'codex'
} else {
    'agent'
}

let trigger = if ($hook_event | is-empty) { 'SessionEnd' } else { $hook_event }
let header = $"**Agent Session Checkpoint** -- ($issue_key)\n\nMetadata:\n- agent: ($agent)\n- model: ($model)\n- session_id: ($session_id)\n- cwd: ($cwd)\n- branch: ($branch)\n- trigger: ($trigger)\n- generated_at: ($now)\n\n_This is a checkpoint. Run `linear-finalize` for the final issue retrospective._\n"

let insights_section = if $has_insights {
    let body = ($insights | str join "\n\n---\n\n")
    $"\n**Insights**:\n\n($body)\n"
} else { '' }

let commits_section = if $has_commits {
    $"\n**Commits** (since origin/main):\n```\n($commits)\n```\n"
} else { '' }

let stat_section = if $has_stat {
    $"\n**Uncommitted changes**:\n```\n($diff_stat)\n```\n"
} else { '' }

let notes_section = if $has_notes {
    $"\n**Session notes**:\n($notes)\n"
} else { '' }

let comment = $"($header)($insights_section)($commits_section)($stat_section)($notes_section)"

do -i {
    ^linear issues comment $issue_key --body $comment
}
