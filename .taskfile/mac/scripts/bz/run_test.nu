use std/assert

def nu-eval [script: string] {
    let result = (^nu -c $script | complete)
    if $result.exit_code != 0 {
        error make {
            msg: $'nu eval failed: ($result.stderr)'
        }
    }

    $result.stdout | str trim
}

def test-extract-bilibili-url [] {
    let result = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; extract-bilibili-url 'https://www.bilibili.com/video/BV1NNrCBPEWC/?spm_id_from=333.1387.homepage.video_card.click&vd_source=abc | title'"
    )

    assert equal $result "https://www.bilibili.com/video/BV1NNrCBPEWC/?spm_id_from=333.1387.homepage.video_card.click&vd_source=abc"
}

def test-task-id-for-url [] {
    let single = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; task-id-for-url 'https://www.bilibili.com/video/BV1NNrCBPEWC'"
    )
    let paged = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; task-id-for-url 'https://www.bilibili.com/video/BV18ZC1BpE8D/?vd_source=x&p=2&spm=1'"
    )

    assert equal $single "BV1NNrCBPEWC"
    assert equal $paged "BV18ZC1BpE8D_p2"
}

def test-derive-task-states [] {
    let raw = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; let events = [{type: 'task_created', id: 'a', url: 'https://example/a', at: '2026-01-01T00:00:00+08:00'}, {type: 'fetch_started', id: 'a', url: 'https://example/a', at: '2026-01-01T00:01:00+08:00'}, {type: 'fetch_succeeded', id: 'a', url: 'https://example/a', subtitle_path: 'raw/a/sub.vtt', at: '2026-01-01T00:02:00+08:00'}, {type: 'transcript_ready', id: 'a', url: 'https://example/a', transcript_path: 'transcript/a.md', at: '2026-01-01T00:03:00+08:00'}, {type: 'task_created', id: 'b', url: 'https://example/b', at: '2026-01-01T00:00:00+08:00'}, {type: 'fetch_failed', id: 'b', url: 'https://example/b', error_type: 'no_subtitle', at: '2026-01-01T00:01:00+08:00'}, {type: 'summary_assembled', out: '/tmp/out.md', item_count: 1, at: '2026-01-01T00:04:00+08:00'}]; derive-task-states $events | to json -r"
    )
    let states = ($raw | from json)
    let a = ($states | where id == "a" | first)
    let b = ($states | where id == "b" | first)

    assert equal ($states | length) 2
    assert equal $a.state "transcript_ready"
    assert equal $b.state "fetch_failed"
}

def test-derive-summary-task-states [] {
    let raw = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; let events = [{type: 'summary_task_created', id: 'a', at: '2026-01-01T00:00:00+08:00'}, {type: 'summary_failed', id: 'a', error_type: 'runner_failed', at: '2026-01-01T00:01:00+08:00'}, {type: 'summary_ready', id: 'a', at: '2026-01-01T00:02:00+08:00'}, {type: 'summary_task_created', id: 'b', at: '2026-01-01T00:00:00+08:00'}, {type: 'summary_failed', id: 'b', error_type: 'invalid_json', at: '2026-01-01T00:03:00+08:00'}, {type: 'summary_assembled', out: '/tmp/out.md', item_count: 1, at: '2026-01-01T00:04:00+08:00'}]; derive-summary-task-states $events | to json -r"
    )
    let states = ($raw | from json)
    let a = ($states | where id == "a" | first)
    let b = ($states | where id == "b" | first)

    assert equal ($states | length) 2
    assert equal $a.state "ready"
    assert equal $b.state "failed"
}

def test-transcript-lines-from-json [] {
    let path = "/tmp/run-test-subs.json"
    '{"events":[{"start":0,"text":"Hello"},{"start":500,"text":"Hello"},{"start":1200,"text":"<i>World</i>"}]}' | save -f $path

    let raw = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; transcript-lines-from-json '/tmp/run-test-subs.json' | to json -r"
    )
    let lines = ($raw | from json)

    assert equal ($lines | length) 2
    assert equal (($lines | first | get timestamp)) "00:00:00"
    assert equal (($lines | last | get text)) "World"
}

def test-failed-urls-output [] {
    let workdir = "/tmp/run-test-failed-urls"
    do { rm -rf $workdir } | ignore
    mkdir $workdir
    mkdir ($workdir | path join "reports")
    mkdir ($workdir | path join "raw")
    mkdir ($workdir | path join "normalized")
    mkdir ($workdir | path join "transcript")
    mkdir ($workdir | path join "logs")

    [
        {type: "task_created", id: "a", url: "https://example/a", at: "2026-01-01T00:00:00+08:00"}
        {type: "fetch_failed", id: "a", url: "https://example/a", error_type: "no_subtitle", at: "2026-01-01T00:01:00+08:00"}
        {type: "task_created", id: "b", url: "https://example/b", at: "2026-01-01T00:00:00+08:00"}
        {type: "transcript_failed", id: "b", url: "https://example/b", error_type: "empty_transcript", at: "2026-01-01T00:02:00+08:00"}
    ]
    | each {|row| $row | to json -r }
    | str join "\n"
    | $"($in)(char nl)"
    | save -f ($workdir | path join "events.jsonl")

    let printed = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; main failed-urls --workdir '/tmp/run-test-failed-urls'"
    )
    let file_lines = (
        open ($workdir | path join "reports" "failed-urls.txt")
        | lines
    )

    assert ($printed | str contains "https://example/a")
    assert ($printed | str contains "https://example/b")
    assert equal ($file_lines | length) 2
}

def test-runner-config [] {
    let codex_raw = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; resolve-runner-config 'codex' | to json -r"
    )
    let codex = ($codex_raw | from json)
    assert equal $codex.agent "codex"
    assert ($codex.runner | str contains "codex")
    assert ($codex.runner | str contains "--model gpt-5.5")
    assert not ($codex.runner | str contains "model_reasoning_effort")

    let inferred_raw = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; resolve-runner-config '' 'claude --model sonnet' | to json -r"
    )
    let inferred = ($inferred_raw | from json)
    assert equal $inferred.agent "claude"
    assert equal $inferred.runner "claude --model sonnet"

    let cc_raw = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; resolve-runner-config '' 'cc --model deepseek-v4-flash' | to json -r"
    )
    let cc_runner = ($cc_raw | from json)
    assert equal $cc_runner.agent "claude"
    assert equal $cc_runner.runner "claude --model deepseek-v4-flash"
}

def test-build-runner-shell-command [] {
    let codex_cmd = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; build-runner-shell-command 'codex' 'codex exec --model gpt-5.5' '/tmp/prompt.txt' '/tmp/runner.log' '/tmp/raw.txt'"
    )
    assert ($codex_cmd | str contains "codex exec --model gpt-5.5 --output-last-message '/tmp/raw.txt' -")
    assert not ($codex_cmd | str contains " -p ")

    let claude_cmd = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; build-runner-shell-command 'claude' 'claude --model sonnet' '/tmp/prompt.txt' '/tmp/runner.log' '/tmp/raw.txt'"
    )
    assert ($claude_cmd | str contains "claude --model sonnet -p")

    let custom_cmd = (
        nu-eval "source .taskfile/mac/scripts/bz/run.nu; build-runner-shell-command 'custom' 'my-runner --json' '/tmp/prompt.txt' '/tmp/runner.log' '/tmp/raw.txt'"
    )
    assert ($custom_cmd | str contains "my-runner --json")
    assert not ($custom_cmd | str contains "my-runner --json -")
    assert not ($custom_cmd | str contains "my-runner --json -p")
}

def main [] {
    test-extract-bilibili-url
    test-task-id-for-url
    test-derive-task-states
    test-derive-summary-task-states
    test-transcript-lines-from-json
    test-failed-urls-output
    test-runner-config
    test-build-runner-shell-command
}
