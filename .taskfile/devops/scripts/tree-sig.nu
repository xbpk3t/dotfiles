#!/usr/bin/env nu

const default_exclude_dirs = '.git,.idea,.cache'

# 校验并标准化 folder 路径。
# 重要：后续所有 path 计算都基于 absolute path，避免 cwd 变化引入歧义。
def normalize-folder [folder: string]: nothing -> string {
    let folder_abs = ($folder | path expand)

    if not ($folder_abs | path exists) {
        error make {
            msg: $"Directory ($folder_abs) does not exist"
        }
    }

    if (($folder_abs | path type) != 'dir') {
        error make {
            msg: $"Path ($folder_abs) is not a directory"
        }
    }

    $folder_abs
}

# 解析 exclude 目录列表。
# 约定使用逗号分隔，避免在 Taskfile 里继续传 shell expression。
def parse-exclude-dirs [exclude_dirs_csv: string]: nothing -> list<string> {
    $exclude_dirs_csv
    | split row ','
    | each {|dir| $dir | str trim }
    | where {|dir| $dir != '' }
}

# 构造 glob exclude patterns。
# 同时排除目录本身与其子树，避免 walker 继续深入被忽略的目录。
def build-exclude-patterns [exclude_dirs: list<string>]: nothing -> list<string> {
    $exclude_dirs
    | each {|dir|
        [
            $'**/($dir)'
            $'**/($dir)/**'
        ]
    }
    | flatten
}

# 列出参与签名的文件。
# 重要：统一返回 absolute path，后续再转换为 relative path 做聚合。
def list-tree-files [folder_abs: string, exclude_dirs_csv: string]: nothing -> list<string> {
    let exclude_dirs = (parse-exclude-dirs $exclude_dirs_csv)
    let exclude_patterns = (build-exclude-patterns $exclude_dirs)

    glob $'($folder_abs)/**/*' --no-dir --exclude $exclude_patterns
    | sort
}

# 解析 stamp 的最终落盘路径。
# 重要：如果传入的是纯文件名，就统一落到 folder 的父目录下 `.task/`，调用侧不再需要传完整路径。
def resolve-stamp-path [folder: string, stamp: string]: nothing -> string {
    let folder_abs = (normalize-folder $folder)
    let looks_like_path = (
        ($stamp | str starts-with '/')
        or ($stamp | str starts-with '~')
        or ($stamp | str contains '/')
    )

    if $looks_like_path {
        $stamp | path expand
    } else {
        let stamp_name = ($stamp | path basename)

        if $stamp_name != $stamp {
            error make {
                msg: $"Stamp name ($stamp) must be a plain file name or an explicit path"
            }
        }

        let stamp_dir = (($folder_abs | path dirname) | path join '.task')
        $stamp_dir | path join $stamp_name
    }
}

# 计算目录树 signature。
# 重要：聚合内容同时包含 file content hash 与 relative path，确保 rename / delete / add 都能反映到结果里。
def compute-tree-signature [folder: string, exclude_dirs_csv: string]: nothing -> string {
    let folder_abs = (normalize-folder $folder)

    let sig_lines = (
        list-tree-files $folder_abs $exclude_dirs_csv
        | each {|file_path|
            let relative_path = ($file_path | path relative-to $folder_abs)
            let content_hash = (open --raw $file_path | hash sha256)
            $'($content_hash)  ($relative_path)'
        }
    )

    $sig_lines
    | append ''
    | str join (char newline)
    | hash sha256
}

def check-tree-signature [
    --folder (-f): string
    --stamp (-s): string
    --exclude-dirs (-e): string = $default_exclude_dirs
] {
    let stamp_abs = (resolve-stamp-path $folder $stamp)

    if not ($stamp_abs | path exists) {
        exit 1
    }

    let current_signature = (compute-tree-signature $folder $exclude_dirs)
    let expected_signature = (open --raw $stamp_abs | str trim)

    if $current_signature == $expected_signature {
        exit 0
    }

    exit 1
}

def write-tree-signature [
    --folder (-f): string
    --stamp (-s): string
    --exclude-dirs (-e): string = $default_exclude_dirs
] {
    let stamp_abs = (resolve-stamp-path $folder $stamp)
    let stamp_dir = ($stamp_abs | path dirname)
    let current_signature = (compute-tree-signature $folder $exclude_dirs)

    mkdir $stamp_dir
    $current_signature | save --force --raw $stamp_abs
}

def main [
    action: string
    --folder (-f): string
    --stamp (-s): string
    --exclude-dirs (-e): string = $default_exclude_dirs
] {
    match $action {
        'check' => {
            check-tree-signature --folder $folder --stamp $stamp --exclude-dirs $exclude_dirs
        }
        'write' => {
            write-tree-signature --folder $folder --stamp $stamp --exclude-dirs $exclude_dirs
        }
        _ => {
            error make {
                msg: $"Unsupported action: ($action)"
            }
        }
    }
}
