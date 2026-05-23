#!/usr/bin/env nu

let scratch_dir = $"($env.HOME)/scratch"

# === Logging ===

def log [msg: string] {
    print -e $"[scratch] ($msg)"
}

# === CLI: testable core commands (no fzf) ===

# Open a scratch file in editor
# Usage: nu run.nu open <path>
def "main open" [path: string] {
    log $"open: ($path)"
    if ($env.CMUX_WORKSPACE_ID? | is-not-empty) {
        let basename = ($path | path basename | str replace '.md' '')
        log $"open: cmux mode, workspace=($env.CMUX_WORKSPACE_ID), name=scratch: ($basename)"
        ^cmux new-workspace --name $"scratch: ($basename)" --cwd $scratch_dir --command $"hx \"($path)\"" --focus true
    } else {
        log "open: standalone hx"
        ^hx $path
    }
}

# Create a new scratch file
# Usage: nu run.nu create <name>
def "main create" [name: string] {
    log $"create: raw=($name)"
    let safe_name = ($name | str replace --all --regex '[^a-zA-Z0-9._-]' '_')
    log $"create: safe=($safe_name)"

    let filepath = if ($safe_name | str ends-with '.md') {
        $"($scratch_dir)/($safe_name)"
    } else {
        $"($scratch_dir)/($safe_name).md"
    }
    log $"create: path=($filepath)"

    mkdir $scratch_dir
    $"# ($safe_name)\n\n" | save -f $filepath
    log "create: saved, opening..."
    main open $filepath
}

# === fzf UI layer ===

# fzf wrapper: handle the unreliable pipe from ls into fzf
# Returns stdout from the pipe, or empty string on any failure
def fzf-from-ls [base_args: list<string>, --print-query (-q)]: nothing -> string {
    let ls_out = (do -i { ^ls -t $"($scratch_dir)/" } | complete)
    log $"fzf-from-ls: ls exit=($ls_out.exit_code)"

    if $ls_out.exit_code != 0 {
        log $"fzf-from-ls: ls stderr=($ls_out.stderr)"
        return ""
    }

    let files = ($ls_out.stdout | str trim)
    log $"fzf-from-ls: ls stdout lines=($files | lines | length)"

    # For --print-query (new command), always run fzf even with empty dir
    # so user can type a filename. For list/rename, skip when empty.
    if ($files | is-empty) and not $print_query {
        return ""
    }

    let fzf_args = ($base_args | append [
        --preview 'bat --color=always --style=numbers,header {}'
    ])

    let fzf_args = if $print_query {
        $fzf_args | append [--print-query --query '']
    } else {
        $fzf_args
    }

    # complete catches fzf's non-zero exit (ESC/no-match) without aborting the pipeline
    $files | ^fzf ...$fzf_args | complete | $in.stdout | str trim
}

# List/search scratch files
# Usage: nu run.nu
def "main" [] {
    log "main: listing scratch files"
    mkdir $scratch_dir

    let selection = (fzf-from-ls [
        --bind 'ctrl-d:execute(rm -i {})+reload(ls -t ~/scratch/)'
        --header 'Enter: open | ctrl-d: delete | type to filter'
        --prompt 'scratch> '
    ])

    log $"main: selection=($selection)"
    if ($selection | is-empty) {
        log "main: nothing selected"
        return
    }

    main open $selection
}

# Create new scratch file via fzf prompt
# Usage: nu run.nu new
def "main new" [] {
    log "new: starting create mode"
    mkdir $scratch_dir

    let result = (fzf-from-ls [
        --header 'Enter: create from query | ESC: cancel'
        --prompt 'new> '
    ] --print-query)

    log $"new: result=($result)"
    if ($result | is-empty) {
        log "new: fzf returned empty"
        return
    }

    let query = ($result | lines | first | str trim)
    log $"new: query=($query)"
    if ($query | is-empty) {
        log "new: empty query"
        return
    }

    main create $query
}

# Rename via fzf selection + input
# Usage: nu run.nu rename
def "main rename" [] {
    log "rename: starting"
    mkdir $scratch_dir

    let selection = (fzf-from-ls [
        --header 'Select file to rename'
        --prompt 'rename> '
    ])

    log $"rename: selection=($selection)"
    if ($selection | is-empty) {
        log "rename: nothing selected"
        return
    }

    let old_name = ($selection | path basename)
    let new_name = (input $"New name for ($old_name): ")
    log $"rename: ($old_name) -> ($new_name)"

    if ($new_name | is-empty) {
        log "rename: empty new name"
        return
    }

    let safe_name = ($new_name | str replace --all --regex '[^a-zA-Z0-9._-]' '_')
    let new_path = $"($scratch_dir)/($safe_name).md"
    log $"rename: mv ($selection) -> ($new_path)"
    mv $selection $new_path
    print $"Renamed: ($old_name) -> ($safe_name).md"
}
