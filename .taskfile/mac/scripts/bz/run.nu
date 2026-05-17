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
        "summary_task_created" => "summary_pending"
        "summary_started" => "summary_in_progress"
        "summary_ready" => "summary_ready"
        "summary_failed" => "summary_failed"
        "summary_skipped" => "summary_skipped"
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
            summary_pending: (count-state $states "summary_pending")
            summary_ready: (count-state $states "summary_ready")
            summary_failed: (count-state $states "summary_failed")
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
    print $'summary_pending: ($report.counts.summary_pending)'
    print $'summary_ready: ($report.counts.summary_ready)'
    print $'summary_failed: ($report.counts.summary_failed)'

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

# ---------------------------------------------------------------------------
# Summary stage helpers
# ---------------------------------------------------------------------------

const default_summary_prompt_version = "single_video_v1"

const summary_schema_json = '{
  "overall_score": "0.0-5.0",
  "processing_quality_score": "0.0-5.0",
  "recommend_original_video": "yes|no|conditional",
  "one_sentence_summary": "string",
  "summary": "string",
  "key_points": [{"point": "string", "evidence": "string", "timestamps": ["string"]}],
  "structure": [{"section": "string", "timestamps": "string", "summary": "string"}],
  "concepts": [{"term": "string", "explanation": "string"}],
  "actionable_items": ["string"],
  "worth_rewatching": [{"timestamp": "string", "reason": "string"}],
  "information_density": "high|medium|low",
  "transcript_quality": "good|fair|poor",
  "uncertainties": ["string"],
  "tags": ["string"]
}'

const summary_required_fields = [
    "overall_score"
    "processing_quality_score"
    "recommend_original_video"
    "one_sentence_summary"
    "summary"
    "key_points"
]

const default_summary_prompt_text = (
    '你是我的视频内容研究助理。下面是一份 B 站视频字幕转录稿。请你只基于转录稿内容，生成一个结构化摘要 JSON。\n\n'
    + '重要要求：\n'
    + '1. 只基于转录稿内容，不要编造视频中没有出现的信息。\n'
    + '2. 不要逐字复述，要提炼观点、结构、结论和可执行信息。\n'
    + '3. 如果字幕疑似识别错误、缺失上下文或无法判断，请写入 uncertainties。\n'
    + '4. 保留重要观点的大致时间戳。\n'
    + '5. 输出必须是合法 JSON，不要输出 Markdown，不要输出解释性文字。不要进入 plan mode，不要创建任何文件，不要使用任何工具。\n'
    + '6. JSON 必须符合给定 schema。\n'
    + '7. title、url、id、uploader、duration_seconds 请优先使用 frontmatter 中的信息，不要自行改写 title。\n'
    + '8. overall_score 和 processing_quality_score 都是 0.0 到 5.0 的数字。\n'
    + '9. recommend_original_video 只能是 yes、no、conditional。\n'
    + '10. 输出中文内容。\n'
    + '11. 重要：JSON 字符串值内部如果出现双引号，必须用反斜杠转义（\"），或者改用中文引号（"" 或「」）。不要直接使用未转义的 ASCII 双引号，否则 JSON 不合法。\n\n'
    + '评分标准：\n'
    + '- overall_score：评价视频内容本身的综合价值，包括信息密度、清晰度、实用性、独特性、是否值得看原视频。\n'
    + '- processing_quality_score：评价基于当前转录稿生成摘要的可靠性，包括字幕完整度、时间戳可用性、识别错误概率、上下文连贯性。\n'
    + '- 如果转录稿很短、重复严重、明显缺失内容，processing_quality_score 应该降低。\n'
    + '- 如果内容信息密度高、结构清晰、观点有用，overall_score 应该提高。\n\n'
    + 'frontmatter:\n{{frontmatter_json}}\n\n'
    + 'schema:\n{{schema_json}}\n\n'
    + 'transcript:\n{{transcript}}'
)

def summary-items-dir [workdir: string] {
    $workdir | path join "summary_items"
}

def summary-prompts-dir [workdir: string] {
    $workdir | path join "summary_prompts"
}

def summary-item-path [workdir: string id: string] {
    $workdir | path join "summary_items" $'($id).json'
}

def summary-log-path [workdir: string id: string] {
    log-path $workdir $id "summary"
}

def summary-raw-output-path [workdir: string id: string] {
    $workdir | path join "logs" $'($id).summary.raw.txt'
}

def summary-ensemble-path [workdir: string] {
    $workdir | path join "summary.md"
}

def parse-frontmatter [file_path: string] {
    let raw = (open $file_path --raw | decode utf-8)
    let lines = ($raw | lines)

    if ($lines | is-empty) or (($lines | first) != "---") {
        return {id: ($file_path | path parse | get stem | str trim), title: null, url: null, uploader: null, duration: null}
    }

    let closing = (
        $lines
        | enumerate
        | skip 1
        | where item == "---"
        | first
    )
    let end_idx = ($closing.index | into int)

    let front_lines = ($lines | skip 1 | take (($end_idx - 1) | into int))

    mut result = {id: ($file_path | path parse | get stem | str trim), title: null, url: null, uploader: null, duration: null}

    for line in $front_lines {
        let parts = ($line | str trim | parse "{key}:{rest}")
        if not ($parts | is-empty) {
            let key = ($parts | first | get key | str trim)
            let val = ($parts | first | get rest | str trim | str replace --all '"' '')
            $result = ($result | upsert $key (
                if $key == "duration" { ($val | into float | default null) } else { $val }
            ))
        }
    }

    $result
}

def extract-transcript-body [file_path: string] {
    let raw = (open $file_path --raw | decode utf-8)
    let lines = ($raw | lines)

    if ($lines | is-empty) or (($lines | first) != "---") {
        return $raw
    }

    let closing = (
        $lines
        | enumerate
        | skip 1
        | where item == "---"
        | first
    )
    let end_idx = ($closing.index | into int)

    ($lines | skip ($end_idx + 1) | str join "\n")
}

def discover-summary-tasks [workdir: string transcript_dir: string] {
    ensure-dir (summary-items-dir $workdir)
    ensure-dir (summary-prompts-dir $workdir)

    let events = (load-events $workdir)
    let existing_ids = (
        $events
        | where type == "summary_task_created"
        | get id
    )

    let md_files = (glob ($transcript_dir | path join "*.md"))

    for f in ($md_files | sort) {
        let fm = (parse-frontmatter $f)
        let id = ($fm.id | str trim)

        if $id not-in $existing_ids {
            append-event $workdir {
                type: "summary_task_created"
                id: $id
                source_path: ($f)
                title: ($fm.title | default $id)
                url: ($fm.url | default "")
                at: (now-iso)
            }
        }
    }
}

def summary-tasks-to-process [workdir: string force: bool] {
    let events = (load-events $workdir)

    let task_ids = (
        $events
        | where type == "summary_task_created"
        | get id
        | uniq
    )

    mut result = []

    for id in $task_ids {
        if $force {
            $result = ($result | append $id)
        } else {
            let item_path = (summary-item-path $workdir $id)
            let has_ready = (
                $events
                | where type == "summary_ready" and id == $id
                | length
            ) > 0

            if not $has_ready {
                $result = ($result | append $id)
            }
        }
    }

    $result
}

def build-summary-prompt [workdir: string transcript_file: string external_prompt?: string] {
    let fm = (parse-frontmatter $transcript_file)
    let body = (extract-transcript-body $transcript_file)

    let prompt_text = if $external_prompt != null {
        open $external_prompt --raw
    } else {
        $default_summary_prompt_text
    }

    let frontmatter_json = ({
        id: $fm.id
        title: ($fm.title | default $fm.id)
        url: ($fm.url | default "")
        uploader: ($fm.uploader | default "")
        duration_seconds: ($fm.duration | default null)
    } | to json -r)

    $prompt_text
    | str replace --all '\n' "\n"
    | str replace "{{frontmatter_json}}" $frontmatter_json
    | str replace "{{schema_json}}" $summary_schema_json
    | str replace "{{transcript}}" $body
}

def invoke-runner [runner_cmd: string prompt_text: string log_file: string raw_file: string] {
    # Write prompt to a temp file
    let prompt_file = ($log_file | path dirname | path join ($log_file | path parse | get stem | $in + ".prompt.txt"))
    $prompt_text | save -f $prompt_file
    let quoted_prompt = (quote-arg $prompt_file)
    let log_quoted = (quote-arg $log_file)
    let raw_quoted = (quote-arg $raw_file)
    # Run: cat prompt | runner -p (non-interactive mode), save stdout to raw_file, stderr to log
    # Note: some runners (e.g. claude -p) exit with code 1 even on success; check stdout instead of exit code
    let wrapped = $'cat ($quoted_prompt) | ($runner_cmd) -p >($raw_quoted) 2>($log_quoted)'
    ^bash -lc $wrapped | complete
}

def first-capture [rows: list] {
    if ($rows | is-empty) { null } else { $rows | first | get capture0 }
}

def extract-json-from-output [raw: string] {
    let trimmed = ($raw | str trim)

    # 1. Direct parse
    let direct = (try { $trimmed | from json } catch { null })
    if $direct != null { return $direct }

    # 2. Extract from ```json ... ``` block
    let json_block = (first-capture ($trimmed | parse --regex '(?s).*?```json\s*(.*?)```.*'))
    if $json_block != null {
        let parsed = (try { $json_block | str trim | from json } catch { null })
        if $parsed != null { return $parsed }
    }

    # 3. Extract from ``` ... ``` block (no language tag)
    let generic_block = (first-capture ($trimmed | parse --regex '(?s).*?```\s*(.*?)```.*'))
    if $generic_block != null {
        let parsed = (try { $generic_block | str trim | from json } catch { null })
        if $parsed != null { return $parsed }
    }

    # 4. Find outermost { } (greedy regex) — keep text for potential repair
    let outer_obj_raw = (first-capture ($trimmed | parse --regex '(?s).*?(\{.*\}).*'))
    if $outer_obj_raw != null {
        let parsed = (try { $outer_obj_raw | from json } catch { null })
        if $parsed != null { return $parsed }

        # 5. Attempt JSON repair via Python helper (handles unescaped quotes inside string values)
        let python_fix = (try {
            let fix_script = ($env.BZ_SCRIPT_DIR | path join "fix_json.py")
            let fixed = ($outer_obj_raw | ^python3 $fix_script 2>/dev/null | complete)
            if ($fixed | get exit_code) == 0 {
                let repaired = (try { ($fixed | get stdout) | str trim | from json } catch { null })
                if $repaired != null { $repaired } else { null }
            } else {
                null
            }
        } catch { null })

        if $python_fix != null { return $python_fix }
    }

    null
}

def validate-summary-json [json_str: string] {
    let extracted = (extract-json-from-output $json_str)
    if $extracted == null {
        return {ok: false, error: "invalid_json", detail: "failed to extract valid JSON from runner output"}
    }
    let parsed = $extracted

    # Must be a record, not a string/number/array
    let type_desc = ($parsed | describe)
    if not ($type_desc | str starts-with "record") {
        return {ok: false, error: "invalid_json", detail: $"expected JSON object, got ($type_desc)"}
    }

    for field in $summary_required_fields {
        if ($parsed | columns | where $it == $field | is-empty) {
            return {ok: false, error: "missing_required_fields", detail: $'missing field: ($field)'}
        }
    }

    let score = ($parsed.overall_score | into float)
    if $score < 0.0 or $score > 5.0 {
        return {ok: false, error: "invalid_score", detail: $'overall_score ($score) out of range 0.0-5.0'}
    }

    let quality_score = ($parsed.processing_quality_score | into float)
    if $quality_score < 0.0 or $quality_score > 5.0 {
        return {ok: false, error: "invalid_score", detail: $'processing_quality_score ($quality_score) out of range 0.0-5.0'}
    }

    let rec = ($parsed.recommend_original_video | str downcase)
    if $rec not-in ["yes", "no", "conditional"] {
        return {ok: false, error: "invalid_recommendation", detail: $'recommend_original_video must be yes/no/conditional, got ($parsed.recommend_original_video)'}
    }

    let key_points = ($parsed.key_points | length)
    if $key_points == 0 {
        return {ok: false, error: "empty_key_points", detail: "key_points array is empty"}
    }

    {ok: true, data: $parsed}
}

def recommend-zh [value: string] {
    match ($value | str downcase) {
        "yes" => "是"
        "no" => "否"
        "conditional" => "视情况"
        _ => $value
    }
}

def join-tags [tags: list] {
    if ($tags | is-empty) { "无" } else { $tags | str join "、" }
}

def render-summary-item-md [item: record] {
    let rec = $item
    let title = ($rec.title | default $rec.id)
    let url = ($rec.url | default "")
    let uploader = ($rec.uploader? | default "")
    let duration_seconds = ($rec.duration_seconds? | default null)
    let duration_str = (if $duration_seconds != null { $'($duration_seconds) 秒' } else { "未知" })
    let overall = ($rec.overall_score | into float)
    let quality = ($rec.processing_quality_score | into float)
    let recommend_zh = (recommend-zh $rec.recommend_original_video)
    let recommend_reason = ($rec.recommendation_reason? | default "")
    let one_sentence = ($rec.one_sentence_summary? | default "无")
    let summary_text = ($rec.summary? | default "无")
    let key_points = ($rec.key_points? | default [])
    let structure = ($rec.structure? | default [])
    let concepts = ($rec.concepts? | default [])
    let actionable = ($rec.actionable_items? | default [])
    let worth_rewatch = ($rec.worth_rewatching? | default [])
    let info_density = ($rec.information_density? | default "未知")
    let transcript_quality = ($rec.transcript_quality? | default "未知")
    let uncertainties = ($rec.uncertainties? | default [])
    let tags = ($rec.tags? | default [])

    let lines = [
        $"## ($title)"
        ""
        "```markdown"
        $"URL: ($url)"
        $"UP主：($uploader)"
        $"时长：($duration_str)"
        $"综合评分：($overall)/5"
        $"处理质量评分：($quality)/5"
        $"是否推荐查看原视频：($recommend_zh)"
        (if ($recommend_reason | str trim | is-empty) { "" } else { $"推荐理由：($recommend_reason)" })
        "```"
        ""
        "### 一句话摘要"
        ""
        ($one_sentence)
        ""
        "### 核心内容"
        ""
        ($summary_text)
        ""
        "### 关键观点"
        ""
    ]

    mut all_lines = $lines

    if ($key_points | is-empty) {
        $all_lines = ($all_lines | append ["无", ""])
    } else {
        for kp in $key_points {
            let point = ($kp.point? | default "")
            let evidence = ($kp.evidence? | default "")
            let timestamps = ($kp.timestamps? | default [])
            let ts_str = (if ($timestamps | is-empty) { "" } else { $"(($timestamps | str join ', '))" })
            $all_lines = ($all_lines | append [$"- ($point)($ts_str)"])
            if not ($evidence | str trim | is-empty) {
                $all_lines = ($all_lines | append [$"  - 支撑：($evidence)"])
            }
        }
        $all_lines = ($all_lines | append [""])
    }

    $all_lines = ($all_lines | append ["### 内容结构", ""])

    if ($structure | is-empty) {
        $all_lines = ($all_lines | append ["无", ""])
    } else {
        for s in $structure {
            let section = ($s.section? | default "")
            let ts = ($s.timestamps? | default "")
            let summary_s = ($s.summary? | default "")
            $all_lines = ($all_lines | append [$"- **($section)**（($ts)）：($summary_s)"])
        }
        $all_lines = ($all_lines | append [""])
    }

    $all_lines = ($all_lines | append ["### 关键概念", ""])

    if ($concepts | is-empty) {
        $all_lines = ($all_lines | append ["无", ""])
    } else {
        for c in $concepts {
            let term = ($c.term? | default "")
            let expl = ($c.explanation? | default "")
            $all_lines = ($all_lines | append [$"- **($term)**：($expl)"])
        }
        $all_lines = ($all_lines | append [""])
    }

    $all_lines = ($all_lines | append ["### 可执行建议", ""])

    if ($actionable | is-empty) {
        $all_lines = ($all_lines | append ["无", ""])
    } else {
        for a in $actionable {
            $all_lines = ($all_lines | append [$"- ($a)"])
        }
        $all_lines = ($all_lines | append [""])
    }

    $all_lines = ($all_lines | append ["### 值得回看的片段", ""])

    if ($worth_rewatch | is-empty) {
        $all_lines = ($all_lines | append ["无", ""])
    } else {
        for w in $worth_rewatch {
            let ts = ($w.timestamp? | default "")
            let reason = ($w.reason? | default "")
            $all_lines = ($all_lines | append [$"- ($ts)：($reason)"])
        }
        $all_lines = ($all_lines | append [""])
    }

    $all_lines = ($all_lines | append [
        "### 信息质量判断"
        ""
        $"- 信息密度：($info_density)"
        $"- 转录稿质量：($transcript_quality)"
        $"- 处理质量评分：($quality)/5"
        ""
        "### 不确定 / 需要核实的地方"
        ""
    ])

    if ($uncertainties | is-empty) {
        $all_lines = ($all_lines | append ["无", ""])
    } else {
        for u in $uncertainties {
            $all_lines = ($all_lines | append [$"- ($u)"])
        }
        $all_lines = ($all_lines | append [""])
    }

    $all_lines = ($all_lines | append [
        "### 标签"
        ""
        (join-tags $tags)
        ""
        "---"
        ""
    ])

    $all_lines | str join "\n"
}

def load-summary-item [workdir: string id: string] {
    let path = (summary-item-path $workdir $id)
    if not (file-exists $path) {
        return null
    }
    let raw = (open $path --raw | decode utf-8)
    let parsed = ($raw | from json)
    $parsed
}

def assemble-summary-md [workdir: string all_ids: list failed_items: list] {
    let header_lines = [
        "# Bilibili 视频摘要"
        ""
        $"Generated at: (now-iso)"
        ""
        $"Total videos: ($all_ids | length)"
        $"Succeeded: (($all_ids | length) - ($failed_items | length))"
        $"Failed: ($failed_items | length)"
        ""
        "---"
        ""
    ]

    mut body_lines = $header_lines

    for id in ($all_ids | sort) {
        let item = (load-summary-item $workdir $id)
        if $item != null {
            $body_lines = ($body_lines | append (render-summary-item-md $item))
        }
    }

    if not ($failed_items | is-empty) {
        $body_lines = ($body_lines | append ["# Failed summaries", ""])
        for f in $failed_items {
            $body_lines = ($body_lines | append [$"- ($f.id): ($f.error_type), see logs/($f.id).summary.log"])
        }
        $body_lines = ($body_lines | append [""])
    }

    $body_lines | str join "\n"
}

# ---------------------------------------------------------------------------
# Summarize subcommands
# ---------------------------------------------------------------------------

def "main summarize" [
    --workdir: string
    --transcript-dir: string
    --out: string
    --runner: string
    --prompt: string
    --force
] {
    if $runner == null {
        error make {msg: "Missing --runner.\nExample:\n  nu run.nu summarize --transcript-dir ./transcript --runner \"cc --model=deepseek-v4-flash --effort high\""}
    }

    check-deps "yt-dlp"

    let effective_workdir = (resolve-workdir $workdir)
    let transcript_dir = (if $transcript_dir != null { $transcript_dir } else { $effective_workdir | path join "transcript" })
    let out_path = (if $out != null { $out } else { summary-ensemble-path $effective_workdir })

    ensure-workdir-structure $effective_workdir

    # Set script dir for helper scripts (fix_json.py)
    $env.BZ_SCRIPT_DIR = ($env.CURRENT_FILE | path dirname)

    # Discover tasks
    discover-summary-tasks $effective_workdir $transcript_dir

    # Get tasks to process
    let to_process = (summary-tasks-to-process $effective_workdir ($force | default false))

    if ($to_process | is-empty) {
        print "All summary tasks are already cached. Use --force to regenerate."
    }

    # Get the frontmatter data for each id (load from events)
    let events = (load-events $effective_workdir)
    let task_events = ($events | where type == "summary_task_created" | sort-by at)

    # Write default prompt to summary_prompts/ if using it
    let prompt_version = $default_summary_prompt_version
    let prompts_dir = (summary-prompts-dir $effective_workdir)
    let prompt_file_path = ($prompts_dir | path join $'($prompt_version).prompt.txt')

    if $prompt == null and not (file-exists $prompt_file_path) {
        $default_summary_prompt_text | save -f $prompt_file_path
    }

    mut failed_items = []

    for id in $to_process {
        let task_event = ($task_events | where id == $id | first | default null)

        if $task_event == null {
            append-event $effective_workdir {
                type: "summary_failed"
                id: $id
                error_type: "unknown"
                error_detail: "no summary_task_created event found"
                log_path: (relative-to-workdir $effective_workdir (summary-log-path $effective_workdir $id))
                at: (now-iso)
            }
            $failed_items = ($failed_items | append {id: $id, error_type: "unknown", error_detail: "no task event"})
            continue
        }

        let source_path = ($task_event.source_path? | default null)
        if $source_path == null or not (file-exists $source_path) {
            append-event $effective_workdir {
                type: "summary_failed"
                id: $id
                error_type: "source_not_found"
                error_detail: $'transcript file not found: ($source_path)'
                log_path: (relative-to-workdir $effective_workdir (summary-log-path $effective_workdir $id))
                at: (now-iso)
            }
            $failed_items = ($failed_items | append {id: $id, error_type: "source_not_found"})
            continue
        }

        # Check cache
        let item_path = (summary-item-path $effective_workdir $id)
        if not ($force | default false) and (file-exists $item_path) {
            append-event $effective_workdir {
                type: "summary_skipped"
                id: $id
                reason: "cached"
                at: (now-iso)
            }
            print $'[summarize] ($id) skipped (cached)'
            continue
        }

        print $'[summarize] ($id) ...'

        append-event $effective_workdir {
            type: "summary_started"
            id: $id
            at: (now-iso)
        }

        let prompt_text = (build-summary-prompt $effective_workdir $source_path $prompt)
        let log_path = (summary-log-path $effective_workdir $id)
        let log_rel = (relative-to-workdir $effective_workdir $log_path)
        let raw_file = (summary-raw-output-path $effective_workdir $id)

        # Invoke runner (saves stdout to raw_file, stderr to log_path)
        let result = (invoke-runner $runner $prompt_text $log_path $raw_file)

        # Read raw output; check if file has content (don't rely on exit code)
        let raw_content = (if (file-exists $raw_file) { open $raw_file --raw | decode utf-8 } else { "" })
        let stdout_str = ($raw_content | str trim)

        if ($stdout_str | is-empty) {
            append-event $effective_workdir {
                type: "summary_failed"
                id: $id
                error_type: "runner_failed"
                error_detail: "runner produced no output"
                log_path: $log_rel
                at: (now-iso)
            }
            $failed_items = ($failed_items | append {id: $id, error_type: "runner_failed"})
            print ([$"[summarize] " $id " failed (no output)"] | str join)
            continue
        }

        # Validate JSON (handles markdown-wrapped output)
        let validation = (validate-summary-json $stdout_str)
        if not $validation.ok {
            append-event $effective_workdir {
                type: "summary_failed"
                id: $id
                error_type: $validation.error
                error_detail: $validation.detail
                log_path: $log_rel
                at: (now-iso)
            }
            $failed_items = ($failed_items | append {id: $id, error_type: $validation.error})
            print $'[summarize] ($id) failed (($validation.error))'
            continue
        }

        # Enrich with frontmatter fields
        let fm = (parse-frontmatter $source_path)
        let enriched = ($validation.data | merge {
            id: $fm.id
            title: ($fm.title | default $fm.id)
            url: ($fm.url | default "")
            uploader: ($fm.uploader | default "")
            duration_seconds: ($fm.duration | default null)
        })

        # Write item JSON
        let write_result = (
            try {
                ensure-dir (summary-items-dir $effective_workdir)
                $enriched | to json | save -f $item_path
                {ok: true}
            } catch {
                {ok: false}
            }
        )

        if not $write_result.ok {
            append-event $effective_workdir {
                type: "summary_failed"
                id: $id
                error_type: "summary_write_failed"
                error_detail: "failed to write summary item JSON"
                log_path: $log_rel
                at: (now-iso)
            }
            $failed_items = ($failed_items | append {id: $id, error_type: "summary_write_failed"})
            print $'[summarize] ($id) failed (write error)'
            continue
        }

        append-event $effective_workdir {
            type: "summary_ready"
            id: $id
            summary_item_path: (relative-to-workdir $effective_workdir $item_path)
            prompt_version: $prompt_version
            runner: $runner
            at: (now-iso)
        }

        print $'[summarize] ($id) ok'
    }

    # Assemble final summary.md
    let all_events = (load-events $effective_workdir)
    let all_task_ids = (
        $all_events
        | where type == "summary_task_created"
        | get id
        | uniq
        | sort
    )

    let ready_ids = (
        $all_events
        | where type == "summary_ready"
        | get id
        | uniq
    )

    let all_failed = (
        if ($failed_items | is-empty) {
            []
        } else {
            $failed_items
        }
    )

    let final_md = (assemble-summary-md $effective_workdir $all_task_ids $all_failed)
    try {
        $final_md | save -f $out_path
    } catch {
        print $'Error: failed to write final summary to ($out_path)'
        return
    }

    append-event $effective_workdir {
        type: "summary_assembled"
        out: $out_path
        item_count: ($ready_ids | length)
        failed_count: ($all_failed | length)
        at: (now-iso)
    }

    # Also write a copy of the prompt if used default
    if $prompt == null and not (file-exists $prompt_file_path) {
        $default_summary_prompt_text | save -f $prompt_file_path
    }

    print ""
    print "Summary complete."
    print ""
    print "Workdir:"
    print $effective_workdir
    print ""
    print "Final summary:"
    print $out_path
    print ""
    print "Summary items:"
    print (summary-items-dir $effective_workdir)
    print ""
    print "Failed report:"
    print ($effective_workdir | path join "reports" "summary_failed.jsonl")
    print ""

    if (sys host | get name) == "macOS" {
        print "Open final summary:"
        print $'open ($out_path)'
    }
}

def "main summary-status" [
    --workdir: string
] {
    let effective_workdir = (resolve-workdir $workdir)
    ensure-workdir-structure $effective_workdir

    let events = (load-events $effective_workdir)

    let task_ids = (
        $events
        | where type == "summary_task_created"
        | get id
        | uniq
    )

    let ready_ids = (
        $events
        | where type == "summary_ready"
        | get id
        | uniq
    )

    let failed_ids = (
        $events
        | where type == "summary_failed"
        | get id
        | uniq
    )

    let skipped_ids = (
        $events
        | where type == "summary_skipped"
        | get id
        | uniq
    )

    let total = ($task_ids | length)
    let ready = ($ready_ids | length)
    let failed = ($failed_ids | length)
    let skipped = ($skipped_ids | length)
    let pending = ($total - $ready - $failed)

    let out = (summary-ensemble-path $effective_workdir)

    let report = {
        workdir: $effective_workdir
        total: $total
        ready: $ready
        failed: $failed
        skipped: $skipped
        pending: $pending
        out: $out
    }

    ensure-dir ($effective_workdir | path join "reports")
    $report | to json | save -f ($effective_workdir | path join "reports" "summary_status.json")

    print $'Workdir: ($effective_workdir)'
    print ""
    print $'Summary tasks: ($total)'
    print $'ready: ($ready)'
    print $'failed: ($failed)'
    print $'skipped: ($skipped)'
    print $'pending: ($pending)'
    print ""
    print "Final summary:"
    print $out
}

def "main summary-failed" [
    --workdir: string
] {
    let effective_workdir = (resolve-workdir $workdir)
    ensure-workdir-structure $effective_workdir

    let events = (load-events $effective_workdir)
    let failed_events = (
        $events
        | where type == "summary_failed"
        | each {|e|
            {
                id: $e.id
                source_path: ($e.source_path? | default "")
                error_type: ($e.error_type? | default "unknown")
                error_detail: ($e.error_detail? | default "")
                log_path: ($e.log_path? | default null)
            }
        }
    )

    ensure-dir ($effective_workdir | path join "reports")
    let failed_path = ($effective_workdir | path join "reports" "summary_failed.jsonl")
    "" | save -f $failed_path

    for row in $failed_events {
        $"($row | to json -r)(char nl)" | save --append $failed_path
        print ($row | to json -r)
    }

    if ($failed_events | is-empty) {
        print "No failed summary tasks."
    }
}

def main [] {
    print "Usage:"
    print "  nu run.nu all urls.txt"
    print "  nu run.nu init urls.txt [--workdir <path>]"
    print "  nu run.nu fetch [--workdir <path>] [--cookies-from-browser <browser>] [--cookies <path>]"
    print "  nu run.nu transcript [--workdir <path>]"
    print "  nu run.nu summarize [--workdir <path>] [--transcript-dir <path>] [--out <path>] --runner <cmd> [--prompt <path>] [--force]"
    print "  nu run.nu status [--workdir <path>]"
    print "  nu run.nu summary-status [--workdir <path>]"
    print "  nu run.nu failed [--workdir <path>]"
    print "  nu run.nu failed-urls [--workdir <path>]"
    print "  nu run.nu summary-failed [--workdir <path>]"
}
