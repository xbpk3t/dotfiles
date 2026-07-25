#!/usr/bin/env nu
# gen-aliases.nu — Generate aliases.json from references/**/*.md frontmatter
#
# Schema (S):
#   name: string        # must equal file stem
#   role: atom | composite
#   description: string # optional
#   pipeline: [name…]   # required non-empty iff role == composite
#
# aliases.json: { "<name>": "<dir>/<stem>", ... }
#
# USAGE: nu gen-aliases.nu   # cwd = zzz/

def get-zzz-dir []: nothing -> string {
    $env.PWD
}

def collect-md-files [ref_dir: string]: nothing -> list<string> {
    ls -f $"($ref_dir)/**/*.md"
        | where type == file
        | get name
        | each {|f| $f | path relative-to $ref_dir }
        | where {|f| not ($f | path basename | str starts-with '.') }
        | sort
}

def parse-frontmatter [path: string]: nothing -> record {
    let lines = (open --raw $path | lines | take 40)
    if ($lines | length) == 0 or ($lines | first) != '---' {
        error make {msg: $"Missing frontmatter in ($path)"}
    }
    let body = ($lines | skip 1 | take while {|l| $l != '---'})
    mut name = ""
    mut role = ""
    mut pipeline = []
    mut in_pipeline = false
    for line in $body {
        if $in_pipeline {
            if $line =~ '^\s*-\s+\S+' {
                let item = ($line | str trim | str replace -r '^-\s+' '' | str trim)
                $pipeline = ($pipeline | append $item)
                continue
            }
            if $line =~ '^\S' {
                $in_pipeline = false
            } else {
                continue
            }
        }
        if $line =~ '^name:\s+' {
            $name = ($line | parse --regex 'name:\s*(?P<val>\S+)' | get 0.val)
        } else if $line =~ '^role:\s+' {
            $role = ($line | parse --regex 'role:\s*(?P<val>\S+)' | get 0.val)
        } else if $line =~ '^pipeline:\s*$' {
            $in_pipeline = true
        } else if $line =~ '^pipeline:\s*\[' {
            # inline list: pipeline: [a, b]
            let inner = ($line | parse --regex 'pipeline:\s*\[(?P<inner>[^\]]*)\]' | get 0.inner)
            $pipeline = (
                if ($inner | str trim | is-empty) { [] } else {
                    $inner | split row ',' | each {|s| $s | str trim} | where {|s| not ($s | is-empty)}
                }
            )
        }
    }
    { name: $name, role: $role, pipeline: $pipeline }
}

def rel-stem [rel_path: string]: nothing -> record {
    let stem = ($rel_path | path parse | get stem)
    let dir = ($rel_path | path dirname)
    let rel = if $dir == '.' or ($dir | is-empty) { $stem } else { $"($dir)/($stem)" }
    { stem: $stem, rel: $rel }
}

def read-entry [ref_dir: string, rel_path: string]: nothing -> record {
    let path = ($ref_dir | path join $rel_path)
    let fm = (parse-frontmatter $path)
    let rs = (rel-stem $rel_path)
    {
        name: $fm.name
        role: $fm.role
        pipeline: $fm.pipeline
        stem: $rs.stem
        rel: $rs.rel
        path: $rel_path
    }
}

def validate-entry [entry: record]: nothing -> record {
    if ($entry.name | is-empty) {
        error make {msg: $"Missing name in ($entry.path)"}
    }
    if $entry.name != $entry.stem {
        error make {msg: $"name '($entry.name)' != filename stem '($entry.stem)' in ($entry.path)"}
    }
    if $entry.role not-in [atom composite] {
        error make {msg: $"role must be atom|composite in ($entry.path), got '($entry.role)'"}
    }
    if $entry.role == composite {
        if ($entry.pipeline | is-empty) {
            error make {msg: $"composite ($entry.name) requires non-empty pipeline"}
        }
    } else if not ($entry.pipeline | is-empty) {
        error make {msg: $"atom ($entry.name) must not declare pipeline"}
    }
    $entry
}

def validate-pipelines [entries: list<record>]: nothing -> nothing {
    let names = ($entries | get name)
    for e in $entries {
        if $e.role != composite { continue }
        for dep in $e.pipeline {
            if $dep not-in $names {
                error make {msg: $"($e.name) pipeline refs unknown name '($dep)'"}
            }
            if $dep == $e.name {
                error make {msg: $"($e.name) pipeline must not ref self"}
            }
        }
    }
    # simple cycle: A lists B and B lists A
    for e in $entries {
        if $e.role != composite { continue }
        for dep in $e.pipeline {
            let other = ($entries | where name == $dep | get 0?)
            if $other == null { continue }
            if $other.role == composite and ($e.name in $other.pipeline) {
                error make {msg: $"pipeline cycle: ($e.name) <-> ($dep)"}
            }
        }
    }
}

def build-aliases [entries: list<record>]: nothing -> record {
    $entries | reduce --fold {} {|it, acc|
        $acc | insert $it.name $it.rel
    }
}

def write-aliases [aliases: record, zzz_dir: string] {
    let path = ($zzz_dir | path join "aliases.json")
    $aliases | to json | save --force $path
    print $"(ansi green)✓(ansi reset) aliases.json — ($aliases | columns | length) names"
}

def main []: nothing -> nothing {
    let zzz_dir = (get-zzz-dir)
    let ref_dir = ($zzz_dir | path join "references")
    let files = (collect-md-files $ref_dir)
    let entries = (
        $files
        | each {|f| read-entry $ref_dir $f}
        | each {|e| validate-entry $e}
    )
    validate-pipelines $entries
    let aliases = (build-aliases $entries)
    write-aliases $aliases $zzz_dir
    for e in ($entries | where role == composite) {
        print $"  composite ($e.name): ($e.pipeline | str join ' → ')"
    }
}
