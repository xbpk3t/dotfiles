#!/usr/bin/env nu

const default_webp_quality = 85

# 校验并标准化 root 目录。
# 重要：后续所有 glob 与输出路径都基于 absolute path，避免 cwd 漂移导致误操作。
def normalize-root [root: string]: nothing -> string {
    let root_abs = ($root | path expand)

    if not ($root_abs | path exists) {
        error make {
            msg: $'Directory does not exist: ($root_abs)'
        }
    }

    if (($root_abs | path type) != 'dir') {
        error make {
            msg: $'Path is not a directory: ($root_abs)'
        }
    }

    $root_abs
}

# 校验 WebP quality。
# 重要：这里继续在 script 层兜底，避免调用方绕过 Taskfile 后传入非法值。
def validate-quality [quality: int]: nothing -> int {
    if $quality < 0 or $quality > 100 {
        error make {
            msg: $'Quality must be between 0 and 100, got ($quality)'
        }
    }

    $quality
}

# 收集文件列表。
# 重要：patterns 显式区分大小写，避免把平台大小写行为隐式交给底层 filesystem。
def collect-files [root_abs: string, patterns: list<string>]: nothing -> list<string> {
    $patterns
    | each {|pattern|
        glob $'($root_abs)/**/($pattern)' --no-dir
    }
    | flatten
    | uniq
    | sort
}

def build-output-path [file_path: string, target_ext: string]: nothing -> string {
    let parsed = ($file_path | path parse)
    # 重要：输出文件名只基于 stem；如果同目录同时存在 sample.jpg 与 sample.png，
    # 二者都会竞争 sample.webp，这里保持“已存在则 skip”的稳定策略，不偷偷改名。
    $parsed.parent | path join $'($parsed.stem).($target_ext)'
}

def run-command [cmd: string, ...args: string]: nothing -> nothing {
    let result = (^$cmd ...$args | complete)

    if $result.exit_code != 0 {
        let stderr_text = ($result.stderr | str trim)
        let stdout_text = ($result.stdout | str trim)

        if $stderr_text != '' {
            print -e $stderr_text
        }

        if $stdout_text != '' {
            print $stdout_text
        }

        error make {
            msg: $'Command failed: ($cmd) ($args | str join " ")'
        }
    }
}

# 仅在目标文件存在时删除 source，避免 external command 成功返回但未产出文件时误删原文件。
def remove-source-if-needed [source_path: string, output_path: string, keep_source: bool]: nothing -> nothing {
    if (not $keep_source) and ($output_path | path exists) {
        rm $source_path
    }
}

def convert-jpg-to-png-file [file_path: string, keep_source: bool]: nothing -> nothing {
    let output_path = (build-output-path $file_path 'png')

    if ($output_path | path exists) {
        print $'skip: ($output_path)'
    } else {
        run-command 'magick' $file_path $output_path
        remove-source-if-needed $file_path $output_path $keep_source
        print $'ok: ($file_path) -> ($output_path)'
    }
}

def convert-to-webp-file [file_path: string, quality: int, keep_source: bool]: nothing -> nothing {
    let output_path = (build-output-path $file_path 'webp')

    if ($output_path | path exists) {
        print $'skip: ($output_path)'
    } else {
        let ext = (($file_path | path parse | get extension) | str downcase)

        let cwebp_args = if $ext == 'png' {
            [
                '-lossless'
                $file_path
                '-o'
                $output_path
            ]
        } else {
            [
                '-q'
                ($quality | into string)
                $file_path
                '-o'
                $output_path
            ]
        }

        run-command 'cwebp' ...$cwebp_args
        remove-source-if-needed $file_path $output_path $keep_source
        print $'ok: ($file_path) -> ($output_path)'
    }
}

# 把当前目录树下的 jpg/jpeg 统一转成 png。
def "main jpg2png" [
    --root (-r): string = '.'
    --keep-source (-k)
] {
    let root_abs = (normalize-root $root)
    let files = (collect-files $root_abs ['*.jpg' '*.JPG' '*.jpeg' '*.JPEG'])

    if ($files | is-empty) {
        print $'No jpg/jpeg files found under ($root_abs)'
    } else {
        $files | each {|file_path|
            convert-jpg-to-png-file $file_path $keep_source
        } | ignore
    }
}

# 把当前目录树下的 jpg/jpeg/png 统一转成 webp。
# 重要：png 默认走 lossless；jpg/jpeg 走 quality 模式。
def "main webp" [
    --root (-r): string = '.'
    --quality (-q): int = $default_webp_quality
    --keep-source (-k)
] {
    let root_abs = (normalize-root $root)
    let checked_quality = (validate-quality $quality)
    let files = (
        collect-files $root_abs [
            '*.jpg'
            '*.JPG'
            '*.jpeg'
            '*.JPEG'
            '*.png'
            '*.PNG'
        ]
    )

    if ($files | is-empty) {
        print $'No jpg/jpeg/png files found under ($root_abs)'
    } else {
        $files | each {|file_path|
            convert-to-webp-file $file_path $checked_quality $keep_source
        } | ignore
    }
}

def main [] {
    print 'Usage: img.nu <jpg2png|webp> [flags]'
}
