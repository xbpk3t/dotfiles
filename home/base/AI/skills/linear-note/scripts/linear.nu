#!/usr/bin/env -S nu --stdin

def fail [message: string, code: int = 1]: nothing -> nothing {
    print --stderr $'linear-note: ($message)'
    exit $code
}

def read-current-branch []: nothing -> string {
    try { ^git rev-parse --abbrev-ref HEAD err> /dev/null } catch { '' } | str trim
}

def issue-from-text [text: string]: nothing -> string {
    let keys = (
        $text
        | parse -r r#'(?i)(LUC-\d+)'#
        | get capture0?
        | default []
        | each {|key| $key | str upcase }
        | uniq
    )

    if ($keys | length) == 1 { $keys.0 } else { '' }
}

def read-jj-bookmarks []: nothing -> string {
    try {
        ^jj log --ignore-working-copy -r 'heads(::@ & bookmarks())' --no-graph --template 'bookmarks ++ "\n"' err> /dev/null
    } catch { '' } | str trim
}

def detect-issue [provided: string, branch: string]: nothing -> string {
    let requested_issue = (issue-from-text $provided)

    if not ($provided | str trim | is-empty) {
        if ($requested_issue | is-empty) {
            fail $'invalid or ambiguous issue: ($provided)' 2
        }

        $requested_issue
    } else {
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
}

def section [title: string, body: string]: nothing -> string {
    let trimmed = ($body | str trim)

    if ($trimmed | is-empty) {
        ''
    } else {
        $"\n## ($title)\n\n($trimmed)\n"
    }
}

def read-git-facts [base_ref: string]: nothing -> string {
    let commits = (
        try { ^git log $"($base_ref)..HEAD" --oneline err> /dev/null } catch { '' }
        | str trim
    )
    let diff_stat = (
        try { ^git diff HEAD --stat err> /dev/null } catch { '' }
        | str trim
    )
    let status = (
        try { ^git status --short err> /dev/null } catch { '' }
        | str trim
    )

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

    $"($commits_section)($diff_section)($status_section)" | str trim
}

def build-metadata [
    agent: string
    model: string
    branch: string
    source: string
]: nothing -> string {
    let now = (date now | format date '%Y-%m-%d %H:%M')

    $"Metadata:\n- agent: ($agent)\n- model: ($model)\n- cwd: (pwd)\n- branch: ($branch)\n- source: ($source)\n- generated_at: ($now)"
}

def build-latest-comment [
    issue_key: string
    body: string
    agent: string
    model: string
    branch: string
]: nothing -> string {
    let metadata = (build-metadata $agent $model $branch 'linear-note/latest')

    $"**Agent Note** -- ($issue_key)\n\n($metadata)\n\n## Note\n\n($body | str trim)\n"
}

def build-end-comment [
    issue_key: string
    body: string
    agent: string
    model: string
    branch: string
    base_ref: string
]: nothing -> string {
    let metadata = (build-metadata $agent $model $branch 'linear-note/end')
    let review_section = (section 'Agent Review' $body)
    let git_section = (section 'Git Facts' (read-git-facts $base_ref))

    $"**Agent Review** -- ($issue_key)\n\n($metadata)\n($review_section)($git_section)"
}

def post-linear-comment [issue_key: string, body: string]: nothing -> int {
    let result = (try {
        $body | ^linear issues comment $issue_key | complete
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
        print --stderr $'linear-note: ($message)'
    }

    $result.exit_code
}

def main [
    mode: string = 'latest'
    --issue: string = ''
    --agent: string = 'agent'
    --model: string = 'unknown'
    --base: string = 'origin/main'
    --dry-run
]: [nothing -> nothing, string -> nothing] {
    let normalized_mode = ($mode | str downcase)

    if $normalized_mode not-in ['latest' 'end'] {
        fail $'unsupported mode: ($mode). Use latest or end.' 2
    }

    let body = ($in | default '' | into string | str trim)

    if ($body | is-empty) {
        fail 'empty body. Pipe the note or review body into this script.'
    }

    let branch = (read-current-branch)
    let issue_key = (detect-issue $issue $branch)

    if ($issue_key | is-empty) {
        fail 'no Linear issue key found. Pass --issue LUC-XXX, run on a luc/LUC-XXX branch, or use a jj bookmark containing LUC-XXX.'
    }

    let comment = if $normalized_mode == 'end' {
        build-end-comment $issue_key $body $agent $model $branch $base
    } else {
        build-latest-comment $issue_key $body $agent $model $branch
    }

    if $dry_run {
        print --stderr $'dry-run: <generated comment> | ^linear issues comment ($issue_key)'
        print $comment
        exit 0
    }

    let exit_code = (post-linear-comment $issue_key $comment)
    exit $exit_code
}
