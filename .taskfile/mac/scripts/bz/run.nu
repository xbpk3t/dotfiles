#!/usr/bin/env nu

const subtitle_extensions = [vtt srt json ass ssa]
const subtitle_language_markers = [zh-CN zh-Hans zh ai-zh]

def now-iso [] {
    date now | format date "%FT%T%:z"
}

def default-workdir [] {
    let today = (date now | format date "%F")
    $"/tmp/bz-($today)"
}

def latest-link [] {
    "/tmp/bz-latest"
}

def resolve-workdir [workdir?: string] {
    if $workdir == null {
        default-workdir
    } else {
        $workdir
    }
}

def ensure-dir [path: string] {
    if not ($path | path exists) {
        mkdir $path
    }
}

def relative-to-workdir [workdir: string path: string] {
    $path | str replace $'($workdir)/' ''
}

def file-exists [path: string] {
    $path | path exists
}

def ensure-workdir-structure [workdir: string] {
    ensure-dir $workdir

    for name in [raw normalized transcript logs reports] {
        ensure-dir ($workdir | path join $name)
    }

    let events_path = ($workdir | path join "events.jsonl")
    if not (file-exists $events_path) {
        "" | save -f $events_path
    }
}

def update-latest-link [workdir: string] {
    let link = (latest-link)

    if (($link | path exists) or ($link | path exists --no-symlink)) {
        let link_type = (ls -D $link | get type | first)
        if $link_type == "symlink" {
            rm $link
        } else {
            print $'Warning: ($link) exists and is not a symlink; skipping update.'
            return
        }
    }

    ^ln -s $workdir $link
}

def ensure-readable-file [path: string label: string] {
    if not (file-exists $path) {
        error make {msg: $'Cannot read ($label): ($path)'}
    }
}

def check-deps [...commands: string] {
    for cmd in $commands {
        if ((which $cmd | length) == 0) {
            error make {
                msg: $'Missing dependency: ($cmd)\nInstall it first, then rerun this command.'
            }
        }
    }
}

# 从脏行里只抽取第一个 B 站 video URL，保留 query string，供后续任务 ID 和 cookies 语义复用。
def extract-bilibili-url [line: string] {
    let matches = (
        $line
        | parse --regex '.*?(?<url>https://www\.bilibili\.com/video/BV[0-9A-Za-z]+(?:/)?(?:\?[^\s|]+)?)'
    )

    if ($matches | is-empty) {
        null
    } else {
        $matches | first | get url
    }
}

def normalize-url [url: string] {
    $url | str replace -r '/\?' '?'
}

def extract-page-from-query [query?: string] {
    if $query == null or ($query | is-empty) {
        null
    } else {
        let matches = ($query | parse --regex '(?:^|.*&)p=(?<page>\d+)(?:&.*|$)')
        if ($matches | is-empty) {
            null
        } else {
            $matches | first | get page
        }
    }
}

def task-id-for-url [url: string] {
    let normalized = (normalize-url $url)
    let parsed = (
        $normalized
        | parse --regex 'https://www\.bilibili\.com/video/(?<bv>BV[0-9A-Za-z]+)(?:/)?(?:\?(?<query>[^\s|]+))?'
    )

    if not ($parsed | is-empty) {
        let row = ($parsed | first)
        let page = (extract-page-from-query ($row.query?))
        if $page == null {
            $row.bv
        } else {
            $'($row.bv)_p($page)'
        }
    } else {
        let digest = ($normalized | hash md5 | str substring 0..7)
        $'url_($digest)'
    }
}

def load-urls [urls_path: string] {
    ensure-readable-file $urls_path "urls.txt"

    open $urls_path
    | lines
    | each {|line|
        let trimmed = ($line | str trim)
        if ($trimmed | is-empty) or ($trimmed | str starts-with "#") {
            null
        } else {
            extract-bilibili-url $trimmed
        }
    }
    | compact
    | each {|url| normalize-url $url }
    | uniq
}

def events-path [workdir: string] {
    $workdir | path join "events.jsonl"
}

def load-events [workdir: string] {
    let path = (events-path $workdir)
    if not (file-exists $path) {
        []
    } else {
        let raw = (open $path --raw | decode utf-8)
        if ($raw | str trim | is-empty) {
            []
        } else {
            $raw | from json --objects
        }
    }
}

def append-event [workdir: string event: record] {
    let path = (events-path $workdir)
    let line = ($event | to json -r)
    $"($line)(char nl)" | save --append $path
}

def created-task-urls [events: list] {
    $events
    | where type == "task_created"
    | get url
}

# 事件重放不是普通打印日志，而是把 append-only JSONL 当作事实来源，重新推导每个任务当前状态。
def state-for-event-type [event_type: string] {
    match $event_type {
        "task_created" => "pending"
        "fetch_started" => "fetching"
        "fetch_succeeded" => "fetched"
        "fetch_failed" => "fetch_failed"
        "transcript_started" => "transcribing"
        "transcript_ready" => "transcript_ready"
        "transcript_failed" => "transcript_failed"
        _ => "pending"
    }
}

def derive-task-states [events: list] {
    $events
    | group-by id
    | items {|id, rows|
        let last_event = ($rows | last)
        {
            id: $id
            url: ($last_event.url? | default ($rows | first | get url?))
            state: (state-for-event-type $last_event.type)
            last_event: $last_event
        }
    }
    | sort-by id
}

def count-state [states: list state_name: string] {
    $states | where state == $state_name | length
}

def raw-dir [workdir: string id: string] {
    $workdir | path join raw $id
}

def transcript-path [workdir: string id: string] {
    $workdir | path join transcript $'($id).md'
}

def normalized-path [workdir: string id: string] {
    $workdir | path join normalized $'($id).json'
}

def log-path [workdir: string id: string suffix: string] {
    $workdir | path join logs $'($id).($suffix).log'
}

def find-files [dir: string pattern: string] {
    try {
        glob ($dir | path join $pattern)
    } catch {
        []
    }
}

def find-info-json [raw_dir: string] {
    let candidates = (find-files $raw_dir "*.info.json")
    if ($candidates | is-empty) {
        null
    } else {
        $candidates | first
    }
}

def subtitle-extension-rank [path: string] {
    let ext = (($path | path parse).extension | str downcase)
    match $ext {
        "vtt" => 0
        "srt" => 1
        "json" => 2
        "ass" => 3
        "ssa" => 4
        _ => 99
    }
}

def subtitle-language-rank [path: string] {
    let name = ($path | path basename)
    if ($name | str contains "zh-CN") {
        0
    } else if ($name | str contains "zh-Hans") {
        1
    } else if ($name | str contains "zh") {
        2
    } else if ($name | str contains "ai-zh") {
        3
    } else {
        4
    }
}

# 多字幕场景按中文目标和可解析格式优先，避免把 danmaku 或弱相关字幕误选成 transcript 输入。
def choose-subtitle-file [raw_dir: string] {
    let candidates = (
        (find-files $raw_dir "*")
        | where {|path|
            let ext = (($path | path parse).extension | str downcase)
            let basename = ($path | path basename)
            ($ext in $subtitle_extensions) and (not ($basename | str ends-with ".info.json"))
        }
        | each {|path|
            {
                path: $path
                ext_rank: (subtitle-extension-rank $path)
                lang_rank: (subtitle-language-rank $path)
                basename: ($path | path basename)
            }
        }
        | sort-by lang_rank ext_rank basename
    )

    if ($candidates | is-empty) {
        null
    } else {
        $candidates | first | get path
    }
}

def metadata-from-info-json [path: string] {
    let raw = (open $path --raw | decode utf-8)
    let meta = ($raw | from json)
    {
        title: ($meta.title? | default null)
        uploader: ($meta.uploader? | default null)
        duration: ($meta.duration? | default null)
        source_id: ($meta.id? | default null)
        webpage_url: ($meta.webpage_url? | default null)
    }
}

def fetch-task-selection [workdir: string] {
    let states = (derive-task-states (load-events $workdir))
    $states | where state == "pending"
}

def transcript-task-selection [workdir: string] {
    let states = (derive-task-states (load-events $workdir))
    $states | where state == "fetched"
}

def quote-arg [value: string] {
    "'" + ($value | str replace --all "'" "'\\''") + "'"
}

def yt-dlp-command [
    url: string
    raw_dir: string
    cookies_from_browser?: string
    cookies?: string
] {
    let output_template = ($raw_dir + "/%(title).100B [%(id)s].%(ext)s")
    let args = [
        "yt-dlp"
        "--skip-download"
        "--write-subs"
        "--write-auto-subs"
        "--sub-langs"
        "zh.*,zh-Hans,zh-CN,ai-zh"
        "--sub-format"
        "vtt/srt/best"
        "--write-info-json"
        "--no-playlist"
        "-o"
        $output_template
    ]

    let args = if $cookies != null {
        $args | append "--cookies" | append $cookies
    } else if $cookies_from_browser != null {
        $args | append "--cookies-from-browser" | append $cookies_from_browser
    } else {
        $args
    }

    let args = ($args | append $url)
    $args | each {|item| quote-arg $item } | str join " "
}

def pysubs2-command [subtitle_path: string output_dir: string] {
    [
        "pysubs2"
        "--to"
        "json"
        "--output-dir"
        $output_dir
        $subtitle_path
    ]
    | each {|item| quote-arg $item }
    | str join " "
}

def run-shell-command [command: string log_file: string] {
    let quoted_log_file = (quote-arg $log_file)
    let wrapped = $'($command) > ($quoted_log_file) 2>&1'
    ^bash -lc $wrapped | complete
}

def format-ts [millis: int] {
    let total = ($millis // 1000)
    let hours = ($total // 3600)
    let minutes = (($total mod 3600) // 60)
    let seconds = ($total mod 60)
    $'($hours | fill --alignment r --width 2 --character "0"):($minutes | fill --alignment r --width 2 --character "0"):($seconds | fill --alignment r --width 2 --character "0")'
}

def clean-text [text: string] {
    $text
    | str replace --all --regex '<[^>]+>' ''
    | str replace --all --regex '\{[^}]+\}' ''
    | str replace --all '\N' ' '
    | str replace --all '\n' ' '
    | str replace --all '\r' ' '
    | str replace --all --regex '&nbsp;' ' '
    | str replace --all --regex '&amp;' '&'
    | str replace --all --regex '&lt;' '<'
    | str replace --all --regex '&gt;' '>'
    | str replace --all --regex '\s+' ' '
    | str trim
}

def transcript-lines-from-json [json_path: string] {
    let raw = (open $json_path --raw | decode utf-8)
    let data = ($raw | from json)

    $data.events
    | each {|event|
        let text = (clean-text ($event.text? | default ""))
        if ($text | is-empty) {
            null
        } else {
            {
                start: ($event.start? | default 0)
                timestamp: (format-ts ($event.start? | default 0))
                text: $text
            }
        }
    }
    | compact
    | reduce --fold [] {|item, acc|
        if ($acc | is-empty) {
            [$item]
        } else {
            let previous = ($acc | last)
            if $previous.text == $item.text {
                $acc
            } else {
                $acc | append $item
            }
        }
    }
}

def render-frontmatter [record: record] {
    [
        "---"
        $'id: "($record.id)"'
        $'url: "($record.url)"'
        $'title: "($record.title | default "")"'
        $'uploader: "($record.uploader | default "")"'
        $'duration: ($record.duration | default "null")'
        $'subtitle_path: "($record.subtitle_path)"'
        $'normalized_path: "($record.normalized_path)"'
        $'generated_at: "($record.generated_at)"'
        "---"
    ] | str join "\n"
}

def render-transcript-markdown [meta: record lines: list] {
    let title = ($meta.title | default $meta.id)
    let frontmatter = (render-frontmatter $meta)
    let transcript_body = (
        $lines
        | each {|line| $'[($line.timestamp)] ($line.text)' }
        | str join "\n"
    )

    [
        $frontmatter
        ""
        $'# ($title)'
        ""
        "## Metadata"
        ""
        $'- ID: ($meta.id)'
        $'- URL: ($meta.url)'
        $'- Uploader: ($meta.uploader | default "")'
        $'- Duration: ($meta.duration | default "unknown") seconds'
        $'- Subtitle: ($meta.subtitle_path)'
        ""
        "## Transcript"
        ""
        $transcript_body
        ""
    ] | str join "\n"
}

def select-normalized-json [output_dir: string] {
    let candidates = (find-files $output_dir "*.json")
    if ($candidates | is-empty) {
        null
    } else {
        $candidates | first
    }
}

def print-workdir-footer [workdir: string] {
    print ""
    print "Transcript folder:"
    print ($workdir | path join "transcript")
    print ""
    print $'To keep the transcripts permanently:'
    print $'cp -R ($workdir | path join "transcript") ./transcript'
}

def "main init" [
    urls_path: string
    --workdir: string
] {
    let effective_workdir = (resolve-workdir $workdir)
    let urls = (load-urls $urls_path)

    ensure-workdir-structure $effective_workdir
    update-latest-link $effective_workdir

    let events = (load-events $effective_workdir)
    let existing_urls = (created-task-urls $events)

    for url in $urls {
        if not ($url in $existing_urls) {
            let id = (task-id-for-url $url)
            append-event $effective_workdir {
                type: "task_created"
                id: $id
                url: $url
                at: (now-iso)
            }
        }
    }

    print $'Initialized workdir: ($effective_workdir)'
}

def "main fetch" [
    --workdir: string
    --cookies-from-browser: string = "chrome"
    --cookies: string
] {
    check-deps "yt-dlp"

    let effective_workdir = (resolve-workdir $workdir)
    ensure-workdir-structure $effective_workdir

    let tasks = (fetch-task-selection $effective_workdir)

    for task in $tasks {
        let id = $task.id
        let url = $task.url
        let current_raw_dir = (raw-dir $effective_workdir $id)
        let current_log_path = (log-path $effective_workdir $id "fetch")

        ensure-dir $current_raw_dir

        append-event $effective_workdir {
            type: "fetch_started"
            id: $id
            url: $url
            raw_dir: (relative-to-workdir $effective_workdir $current_raw_dir)
            log_path: (relative-to-workdir $effective_workdir $current_log_path)
            at: (now-iso)
        }

        print $'[fetch] ($id) ...'

        let command = (yt-dlp-command $url $current_raw_dir $cookies_from_browser $cookies)
        let result = (run-shell-command $command $current_log_path)

        let subtitle_path = (choose-subtitle-file $current_raw_dir)
        let info_json_path = (find-info-json $current_raw_dir)

        if $subtitle_path == null {
            append-event $effective_workdir {
                type: "fetch_failed"
                id: $id
                url: $url
                error_type: "no_subtitle"
                error_detail: "yt-dlp completed but no supported subtitle file was found"
                log_path: (relative-to-workdir $effective_workdir $current_log_path)
                at: (now-iso)
            }
            print $'[fetch] ($id) failed'
        } else if ($result.exit_code != 0 and $info_json_path == null) {
            append-event $effective_workdir {
                type: "fetch_failed"
                id: $id
                url: $url
                error_type: "yt_dlp_failed"
                error_detail: $'yt-dlp exited with code ($result.exit_code)'
                log_path: (relative-to-workdir $effective_workdir $current_log_path)
                at: (now-iso)
            }
            print $'[fetch] ($id) failed'
        } else {
            let meta = if $info_json_path == null {
                {}
            } else {
                metadata-from-info-json $info_json_path
            }

            let event = {
                type: "fetch_succeeded"
                id: $id
                url: $url
                raw_dir: (relative-to-workdir $effective_workdir $current_raw_dir)
                subtitle_path: (relative-to-workdir $effective_workdir $subtitle_path)
                info_json_path: (if $info_json_path == null { null } else { relative-to-workdir $effective_workdir $info_json_path })
                title: ($meta.title? | default null)
                uploader: ($meta.uploader? | default null)
                duration: ($meta.duration? | default null)
                at: (now-iso)
            }

            let event = if $info_json_path == null {
                $event | upsert metadata_warning "missing_info_json"
            } else {
                $event
            }

            append-event $effective_workdir $event
            print $'[fetch] ($id) ok'
        }
    }
}

def "main transcript" [
    --workdir: string
] {
    check-deps "pysubs2"

    let effective_workdir = (resolve-workdir $workdir)
    ensure-workdir-structure $effective_workdir

    let tasks = (transcript-task-selection $effective_workdir)

    for task in $tasks {
        let last_event = $task.last_event
        let id = $task.id
        let url = $task.url
        let subtitle_rel = ($last_event.subtitle_path? | default null)

        if $subtitle_rel == null {
            append-event $effective_workdir {
                type: "transcript_failed"
                id: $id
                url: $url
                error_type: "unknown"
                error_detail: "missing subtitle_path from fetch_succeeded event"
                at: (now-iso)
            }
            continue
        }

        let subtitle_abs = ($effective_workdir | path join $subtitle_rel)
        let current_log_path = (log-path $effective_workdir $id "transcript")
        let temp_output_dir = ($effective_workdir | path join normalized $'($id)-tmp')
        let final_normalized_path = (normalized-path $effective_workdir $id)
        let final_transcript_path = (transcript-path $effective_workdir $id)

        ensure-dir $temp_output_dir

        append-event $effective_workdir {
            type: "transcript_started"
            id: $id
            url: $url
            at: (now-iso)
        }

        print $'[transcript] ($id) ...'

        let command = (pysubs2-command $subtitle_abs $temp_output_dir)
        let result = (run-shell-command $command $current_log_path)

        if $result.exit_code != 0 {
            append-event $effective_workdir {
                type: "transcript_failed"
                id: $id
                url: $url
                error_type: "pysubs2_failed"
                error_detail: $'pysubs2 exited with code ($result.exit_code)'
                log_path: (relative-to-workdir $effective_workdir $current_log_path)
                at: (now-iso)
            }
            print $'[transcript] ($id) failed'
            continue
        }

        let generated_json = (select-normalized-json $temp_output_dir)
        if $generated_json == null {
            append-event $effective_workdir {
                type: "transcript_failed"
                id: $id
                url: $url
                error_type: "pysubs2_failed"
                error_detail: "pysubs2 completed but no json output was found"
                log_path: (relative-to-workdir $effective_workdir $current_log_path)
                at: (now-iso)
            }
            print $'[transcript] ($id) failed'
            continue
        }

        mv -f $generated_json $final_normalized_path

        let lines = (transcript-lines-from-json $final_normalized_path)
        if ($lines | is-empty) {
            append-event $effective_workdir {
                type: "transcript_failed"
                id: $id
                url: $url
                error_type: "empty_transcript"
                error_detail: "normalized subtitle contained no usable transcript lines"
                log_path: (relative-to-workdir $effective_workdir $current_log_path)
                at: (now-iso)
            }
            print $'[transcript] ($id) failed'
            continue
        }

        let meta = {
            id: $id
            url: $url
            title: ($last_event.title? | default $id)
            uploader: ($last_event.uploader? | default null)
            duration: ($last_event.duration? | default null)
            subtitle_path: $subtitle_rel
            normalized_path: (relative-to-workdir $effective_workdir $final_normalized_path)
            generated_at: (now-iso)
        }

        let markdown = (render-transcript-markdown $meta $lines)
        try {
            $markdown | save -f $final_transcript_path
        } catch {
            append-event $effective_workdir {
                type: "transcript_failed"
                id: $id
                url: $url
                error_type: "transcript_write_failed"
                error_detail: "failed to write transcript markdown"
                log_path: (relative-to-workdir $effective_workdir $current_log_path)
                at: (now-iso)
            }
            print $'[transcript] ($id) failed'
            continue
        }

        append-event $effective_workdir {
            type: "transcript_ready"
            id: $id
            url: $url
            subtitle_path: $subtitle_rel
            normalized_path: (relative-to-workdir $effective_workdir $final_normalized_path)
            transcript_path: (relative-to-workdir $effective_workdir $final_transcript_path)
            at: (now-iso)
        }

        print $'[transcript] ($id) ok'
    }
}

def "main status" [
    --workdir: string
] {
    let effective_workdir = (resolve-workdir $workdir)
    ensure-workdir-structure $effective_workdir

    let states = (derive-task-states (load-events $effective_workdir))
    let total = ($states | length)

    let report = {
        workdir: $effective_workdir
        total: $total
        counts: {
            pending: (count-state $states "pending")
            fetched: (count-state $states "fetched")
            transcript_ready: (count-state $states "transcript_ready")
            fetch_failed: (count-state $states "fetch_failed")
            transcript_failed: (count-state $states "transcript_failed")
        }
        transcript_dir: ($effective_workdir | path join "transcript")
    }

    $report | to json | save -f ($effective_workdir | path join reports status.json)

    print $'Workdir: ($effective_workdir)'
    print ""
    print $'Total: ($total)'
    print $'pending: ($report.counts.pending)'
    print $'fetched: ($report.counts.fetched)'
    print $'transcript_ready: ($report.counts.transcript_ready)'
    print $'fetch_failed: ($report.counts.fetch_failed)'
    print $'transcript_failed: ($report.counts.transcript_failed)'

    print-workdir-footer $effective_workdir
}

def "main failed" [
    --workdir: string
] {
    let effective_workdir = (resolve-workdir $workdir)
    ensure-workdir-structure $effective_workdir

    let states = (derive-task-states (load-events $effective_workdir))
    let failed_rows = (
        $states
        | where state in ["fetch_failed" "transcript_failed"]
        | each {|row|
            let event = $row.last_event
            {
                id: $row.id
                url: ($row.url | default "")
                state: $row.state
                error_type: ($event.error_type? | default "unknown")
                error_detail: ($event.error_detail? | default "")
                log_path: ($event.log_path? | default null)
            }
        }
    )

    let failed_path = ($effective_workdir | path join reports failed.jsonl)
    "" | save -f $failed_path
    for row in $failed_rows {
        $"($row | to json -r)(char nl)" | save --append $failed_path
        print ($row | to json -r)
    }
}

def "main failed-urls" [
    --workdir: string
] {
    let effective_workdir = (resolve-workdir $workdir)
    ensure-workdir-structure $effective_workdir

    let states = (derive-task-states (load-events $effective_workdir))
    let failed_urls = (
        $states
        | where state in ["fetch_failed" "transcript_failed"]
        | get url
        | compact
        | uniq
    )

    let failed_urls_path = ($effective_workdir | path join reports failed-urls.txt)
    "" | save -f $failed_urls_path

    for url in $failed_urls {
        $"($url)(char nl)" | save --append $failed_urls_path
        print $url
    }
}

def "main all" [
    urls_path: string
    --workdir: string
    --cookies-from-browser: string = "chrome"
    --cookies: string
] {
    let effective_workdir = (resolve-workdir $workdir)
    main init $urls_path --workdir $effective_workdir

    if $cookies != null {
        main fetch --workdir $effective_workdir --cookies $cookies
    } else {
        main fetch --workdir $effective_workdir --cookies-from-browser $cookies_from_browser
    }

    main transcript --workdir $effective_workdir
    main status --workdir $effective_workdir
    main failed-urls --workdir $effective_workdir
}

def main [] {
    print "Usage:"
    print "  nu run.nu all urls.txt"
    print "  nu run.nu init urls.txt [--workdir <path>]"
    print "  nu run.nu fetch [--workdir <path>] [--cookies-from-browser <browser>] [--cookies <path>]"
    print "  nu run.nu transcript [--workdir <path>]"
    print "  nu run.nu status [--workdir <path>]"
    print "  nu run.nu failed [--workdir <path>]"
    print "  nu run.nu failed-urls [--workdir <path>]"
}
