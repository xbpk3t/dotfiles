#!/usr/bin/env -S nu --stdin

# SessionEnd hook: post a lightweight checkpoint for Claude Code sessions.
# Final retrospectives are produced explicitly with linear-finalize.
# If an old Codex config still invokes this from Stop, skip it because Codex Stop
# is turn-scoped and would otherwise create repeated Linear comments.

let input = ($in | from json)
let hook_event = ($input.hook_event_name? | default '')

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

def log-hook-error [event: string, issue_key: string, message: string]: nothing -> nothing {
    let now = (date now | format date '%Y-%m-%d %H:%M:%S')
    let log_file = (read-env 'LINEAR_HOOK_LOG' '/tmp/linear-agent-hooks.log')
    let clean_message = ($message | str trim | str replace --all "\n" ' ')
    do -i { $"($now)\t($event)\tissue=($issue_key)\t($clean_message)\n" | save --append $log_file }
}

def post-linear-comment [issue_key: string, body: string, event: string]: nothing -> int {
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
    }

    $result.exit_code
}

if $hook_event == 'Stop' {
    exit 0
}

let cwd = ($input.cwd? | default '.')
if ($cwd | path exists) {
    cd $cwd
} else {
    exit 0
}

let branch = (read-current-branch)

# Detect Linear issue key: env first, then git branch (Codex fallback)
let issue_key = if (not ($env.CLAUDE_LINEAR_ISSUE? | default '' | is-empty)) {
    $env.CLAUDE_LINEAR_ISSUE?
} else {
    issue-from-context $branch
}

if ($issue_key | is-empty) {
    exit 0
}

# ── Git info ──

let commits = (try { ^git log origin/main..HEAD --oneline err> /dev/null } catch { '' } | str trim)

let diff_stat = (try { ^git diff HEAD --stat err> /dev/null } catch { '' } | str trim)

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

if (not $has_insights) and (not $has_commits) and (not $has_stat) {
    exit 0
}

# ── Build comment ──

let now = (date now | format date '%Y-%m-%d %H:%M')
let session_id = ($input.session_id? | default 'unknown')
let model = ($input.model? | default ($env.LINEAR_MODEL? | default 'unknown'))
let configured_agent = ($env.LINEAR_AGENT? | default '')
let agent = if (not ($configured_agent | is-empty)) {
    $configured_agent
} else if (not ($env.CLAUDE_LINEAR_ISSUE? | default '' | is-empty)) or (not ($env.CLAUDE_ENV_FILE? | default '' | is-empty)) {
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

let comment = $"($header)($insights_section)($commits_section)($stat_section)"

let _exit_code = (post-linear-comment $issue_key $comment 'session-checkpoint-comment')
