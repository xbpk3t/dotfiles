#!/usr/bin/env -S nu --stdin

# PostToolUse hook: when ExitPlanMode is called, post the plan content
# as a real-time comment on the linked Linear issue.
# Works on both Claude Code (CLAUDE_LINEAR_ISSUE env) and Codex (git branch fallback).

let input = ($in | from json)
let cwd = ($input.cwd? | default '')

if (not ($cwd | is-empty)) and ($cwd | path exists) {
    cd $cwd
} else if (not ($cwd | is-empty)) {
    exit 0
}

let branch = (try { ^git rev-parse --abbrev-ref HEAD err> /dev/null } catch { '' } | str trim)

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
let tool_name = ($input.tool_name? | default '')

if $tool_name != 'ExitPlanMode' {
    exit 0
}

let plan = ($input.tool_input? | default {} | get plan? | default '')

if ($plan | is-empty) {
    exit 0
}

let now = (date now | format date '%Y-%m-%d %H:%M')
let session_id = ($input.session_id? | default 'unknown')
let model = ($input.model? | default 'unknown')
let hook_event = ($input.hook_event_name? | default 'PostToolUse')
let agent = if (not ($env.CLAUDE_LINEAR_ISSUE? | default '' | is-empty)) or (not ($env.CLAUDE_ENV_FILE? | default '' | is-empty)) {
    'claude-code'
} else if $model != 'unknown' {
    'codex'
} else {
    'agent'
}

let body = $"**Agent Plan** -- ($issue_key)\n\nMetadata:\n- agent: ($agent)\n- model: ($model)\n- session_id: ($session_id)\n- cwd: ($cwd)\n- branch: ($branch)\n- trigger: ($hook_event)/($tool_name)\n- generated_at: ($now)\n\n## Plan\n\n($plan)\n"
let plan_file = $"/tmp/linear-session-plan-($issue_key).md"
let plan_checkpoint = $"## ($now)\n\nMetadata:\n- agent: ($agent)\n- model: ($model)\n- session_id: ($session_id)\n- cwd: ($cwd)\n- branch: ($branch)\n- trigger: ($hook_event)/($tool_name)\n\n($plan)\n\n"

do -i {
    $plan_checkpoint | save --append $plan_file
}

do -i {
    ^linear issues comment $issue_key --body $body
}
