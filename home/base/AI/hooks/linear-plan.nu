#!/usr/bin/env -S nu --stdin

# PostToolUse hook: when ExitPlanMode is called, post the plan content
# as a real-time comment on the linked Linear issue.
# Works on both Claude Code (CLAUDE_LINEAR_ISSUE env) and Codex (git branch fallback).

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

def format-plan-items [items: list]: nothing -> string {
    $items
    | each {|item|
        let step = ($item.step? | default '' | into string | str trim)
        let status = ($item.status? | default '' | into string | str trim)
        if ($step | is-empty) {
            ''
        } else if ($status | is-empty) {
            $'- ($step)'
        } else {
            $'- [($status)] ($step)'
        }
    }
    | where {|line| not ($line | is-empty) }
    | str join "\n"
}

def format-plan [tool_input: record]: nothing -> string {
    let raw_plan = ($tool_input | get plan? | default null)
    let message = ($tool_input | get message? | default '' | into string | str trim)
    let explanation = ($tool_input | get explanation? | default '' | into string | str trim)

    let raw_plan_type = if $raw_plan == null { '' } else { $raw_plan | describe }
    let plan_body = if $raw_plan == null {
        ''
    } else if (($raw_plan_type | str starts-with 'list') or ($raw_plan_type | str starts-with 'table')) {
        format-plan-items $raw_plan
    } else {
        try { $raw_plan | into string | str trim } catch { $raw_plan | to nuon | str trim }
    }

    let sections = [
        (if ($explanation | is-empty) { '' } else { $"Explanation:\n($explanation)" })
        $plan_body
        $message
    ]

    $sections | where {|section| not ($section | is-empty) } | str join "\n\n"
}

let cwd = ($input.cwd? | default '')

if (not ($cwd | is-empty)) and ($cwd | path exists) {
    cd $cwd
} else if (not ($cwd | is-empty)) {
    exit 0
}

let branch = (read-current-branch)

let issue_key = if (not ($env.CLAUDE_LINEAR_ISSUE? | default '' | is-empty)) {
    $env.CLAUDE_LINEAR_ISSUE?
} else {
    issue-from-branch $branch
}

if ($issue_key | is-empty) {
    exit 0
}
let tool_name = ($input.tool_name? | default '')

if $tool_name not-in ['ExitPlanMode' 'update_plan'] {
    exit 0
}

let tool_input = ($input.tool_input? | default {})
let plan = (format-plan $tool_input)

if ($plan | is-empty) {
    exit 0
}

let now = (date now | format date '%Y-%m-%d %H:%M')
let session_id = ($input.session_id? | default 'unknown')
let model = ($input.model? | default ($env.LINEAR_MODEL? | default 'unknown'))
let hook_event = ($input.hook_event_name? | default 'PostToolUse')
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

let body = $"**Agent Plan** -- ($issue_key)\n\nMetadata:\n- agent: ($agent)\n- model: ($model)\n- session_id: ($session_id)\n- cwd: ($cwd)\n- branch: ($branch)\n- trigger: ($hook_event)/($tool_name)\n- generated_at: ($now)\n\n## Plan\n\n($plan)\n"
let plan_file = $"/tmp/linear-session-plan-($issue_key).md"
let plan_checkpoint = $"## ($now)\n\nMetadata:\n- agent: ($agent)\n- model: ($model)\n- session_id: ($session_id)\n- cwd: ($cwd)\n- branch: ($branch)\n- trigger: ($hook_event)/($tool_name)\n\n($plan)\n\n"

try {
    $plan_checkpoint | save --append $plan_file
} catch {|err|
    log-hook-error 'plan-checkpoint' $issue_key ($err.msg? | default 'failed to save plan checkpoint')
}

let _exit_code = (post-linear-comment $issue_key $body 'plan-comment')
