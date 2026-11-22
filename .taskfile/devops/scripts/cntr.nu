#!/usr/bin/env nu

# .cntr compose control-plane helper.
#
# Docker Compose remains the single lifecycle owner. This script only:
#   - reconciles every stack with `docker compose up -d --remove-orphans`
#   - reports status / config-hash drift
#   - ensures the shared `edge` network exists
#
# It never edits compose files and never removes volumes.

const DEV_STACKS = ['golang']
const EDGE_NETWORK = 'edge'

# Treat common "on" values as a boolean flag. Used for env-var fallbacks so
# the Taskfile can stay a thin wrapper without shadowing CLI overrides.
def env-flag [name: string]: nothing -> bool {
    let value = ($env | get -o $name | default '' | into string | str lowercase)
    $value in ['1' 'true' 'yes' 'on']
}

# Resolve the directory that holds one subdirectory per compose stack.
def resolve-cntr-dir [cntr_dir: string]: nothing -> string {
    let from_env = ($env | get -o 'CNTR_DIR' | default '')
    let dir = if not ($cntr_dir | is-empty) {
        $cntr_dir
    } else if not ($from_env | is-empty) {
        $from_env
    } else {
        $env.HOME | path join '.cntr'
    }

    if not ($dir | path exists) {
        error make { msg: $'cntr dir not found: ($dir)' }
    }

    $dir | path expand
}

# Resolve the sops-rendered env file. An explicitly passed path must exist;
# the default path is optional so the script stays backward compatible with
# shell-provided secrets.
def resolve-env-file [env_file: string]: nothing -> string {
    let from_env = ($env | get -o 'CNTR_ENV_FILE' | default '')
    let candidate = if not ($env_file | is-empty) { $env_file } else { $from_env }

    if not ($candidate | is-empty) {
        if not ($candidate | path exists) {
            error make { msg: $'env file not found: ($candidate)' }
        }
        $candidate | path expand
    } else {
        let default = ($env.HOME | path join '.config' 'cntr' 'env')
        if ($default | path exists) { $default } else { '' }
    }
}

# Discover stacks by looking for <stack>/compose.yml.
def discover-stacks [root: string, --include-dev]: nothing -> list<record> {
    let files = (glob ($root | path join '*/compose.yml'))
    let stacks = ($files | each {|file|
        let dir = ($file | path dirname)
        {
            name: ($dir | path basename)
            dir: $dir
            file: $file
        }
    } | sort-by name)

    if $include_dev {
        $stacks
    } else {
        $stacks | where {|stack| $stack.name not-in $DEV_STACKS }
    }
}

# Build the common `docker compose` argument prefix.
def compose-args [stack: record, env_file: string]: nothing -> list<string> {
    let env_args = if ($env_file | is-empty) { [] } else { ['--env-file' $env_file] }
    ['compose'] | append $env_args | append ['--project-directory' $stack.dir '-f' $stack.file]
}

# Run a compose subcommand and capture exit code + output.
def run-compose [stack: record, env_file: string, args: list<string>]: nothing -> record {
    let base = (compose-args $stack $env_file)
    let result = (^docker ...$base ...$args | complete)

    {
        stack: $stack.name
        ok: ($result.exit_code == 0)
        exit_code: $result.exit_code
        stdout: ($result.stdout | str trim)
        stderr: ($result.stderr | str trim)
    }
}

# The shared ingress network is external to every stack and has no compose
# owner. Create it idempotently before any `up`.
def ensure-edge-network []: nothing -> nothing {
    let inspect = (^docker network inspect $EDGE_NETWORK | complete)
    if $inspect.exit_code == 0 { return }

    let created = (^docker network create $EDGE_NETWORK | complete)
    if $created.exit_code != 0 {
        error make { msg: $'failed to create ($EDGE_NETWORK) network: ($created.stderr | str trim)' }
    }
}

# `docker compose ps --format json` is NDJSON in Compose v2 and a JSON array
# in newer releases. Accept both.
def parse-json-lines [raw: string]: nothing -> list<record> {
    let text = ($raw | str trim)
    if ($text | is-empty) {
        []
    } else if ($text | str starts-with '[') {
        try {
            $text | from json
        } catch {|err|
            error make {msg: $'invalid docker compose JSON: ($err.msg)'}
        }
    } else {
        $text
        | lines
        | where {|line| ($line | str trim) != '' }
        | each {|line|
            try {
                $line | from json
            } catch {|err|
                error make {msg: $'invalid docker compose JSON line: ($err.msg)'}
            }
        }
    }
}

def ps-rows [stack: record, env_file: string, --all]: nothing -> list<record> {
    let all_args = if $all { ['-a'] } else { [] }
    let result = (run-compose $stack $env_file (['ps'] | append $all_args | append ['--format' 'json']))
    if not $result.ok {
        error make { msg: $'docker compose ps failed for ($stack.name): ($result.stderr)' }
    }
    parse-json-lines $result.stdout
}

def desired-services [stack: record, env_file: string]: nothing -> list<string> {
    let result = (run-compose $stack $env_file ['config' '--services'])
    if not $result.ok {
        error make { msg: $'docker compose config failed for ($stack.name): ($result.stderr)' }
    }
    $result.stdout | lines | each {|line| $line | str trim } | where {|line| $line != '' }
}

# Compare desired services from the compose file with actual containers.
def status-rows [stack: record, env_file: string]: nothing -> list<record> {
    let desired = (desired-services $stack $env_file)
    let actual = (ps-rows $stack $env_file --all)

    let desired_rows = ($desired | each {|service|
        let matches = ($actual | where {|row| ($row.Service? | default '') == $service })
        if ($matches | is-empty) {
            [{
                stack: $stack.name
                service: $service
                state: 'missing'
                health: '-'
                image: '-'
            }]
        } else {
            $matches | each {|row|
                {
                    stack: $stack.name
                    service: $service
                    state: ($row.State? | default 'unknown')
                    health: (if (($row.Health? | default '') | is-empty) { '-' } else { $row.Health })
                    image: ($row.Image? | default '-')
                }
            }
        }
    } | flatten)

    let orphan_rows = ($actual | where {|row| (($row.Service? | default '') != '') and (($row.Service? | default '') not-in $desired) } | each {|row|
        {
            stack: $stack.name
            service: ($row.Service? | default '?')
            state: 'orphan'
            health: (if (($row.Health? | default '') | is-empty) { '-' } else { $row.Health })
            image: ($row.Image? | default '-')
        }
    })

    $desired_rows | append $orphan_rows
}

# `docker compose config --hash '*'` prints one `service hash` line per service.
def desired-hashes [stack: record, env_file: string]: nothing -> record {
    let result = (run-compose $stack $env_file ['config' '--hash' '*'])
    if not $result.ok {
        {}
    } else {
        $result.stdout | lines | where {|line| ($line | str trim) != '' } | reduce --fold {} {|line, acc|
            let parts = ($line | split row ' ')
            if (($parts | length) >= 2) {
                $acc | upsert ($parts | first) ($parts | last)
            } else {
                $acc
            }
        }
    }
}

def short-hash [hash: string]: nothing -> string {
    if ($hash | str length) > 12 { $hash | str substring 0..11 } else { $hash }
}

# Reconcile every stack. Failure in one stack does not stop the others.
def "main reconcile" [
    --cntr-dir: string = ''
    --env-file: string = ''
    --include-dev
    --dry-run
]: nothing -> nothing {
    let include_dev_flag = ($include_dev or (env-flag 'CNTR_INCLUDE_DEV'))
    let dry_run_flag = ($dry_run or (env-flag 'CNTR_DRY_RUN'))
    let root = (resolve-cntr-dir $cntr_dir)
    let stacks = (discover-stacks $root --include-dev=$include_dev_flag)
    let env_file = (resolve-env-file $env_file)

    if $dry_run_flag {
        for stack in $stacks {
            print $'would run: docker compose --project-directory ($stack.dir) -f ($stack.file) up -d --remove-orphans'
        }
        return
    }

    ensure-edge-network

    let results = ($stacks | each {|stack|
        run-compose $stack $env_file ['up' '-d' '--remove-orphans']
    })

    print ($results | select stack ok exit_code | table --expand)

    let failed = ($results | where {|row| not $row.ok })
    if (($failed | length) > 0) {
        for row in $failed { print -e $'($row.stack): ($row.stderr)' }
        exit 1
    }
}

# Print a status table. --strict exits 1 on any drift, so it can also serve as
# a Task `status:` gate.
def "main status" [
    --cntr-dir: string = ''
    --env-file: string = ''
    --include-dev
    --strict
    --quiet
]: nothing -> nothing {
    let include_dev_flag = ($include_dev or (env-flag 'CNTR_INCLUDE_DEV'))
    let strict_flag = ($strict or (env-flag 'CNTR_STRICT'))
    let root = (resolve-cntr-dir $cntr_dir)
    let stacks = (discover-stacks $root --include-dev=$include_dev_flag)
    let env_file = (resolve-env-file $env_file)
    let rows = ($stacks | each {|stack| status-rows $stack $env_file } | flatten)

    if not $quiet {
        print ($rows | table --expand)
    }

    let bad = ($rows | where {|row| $row.state != 'running' or $row.health == 'unhealthy' })
    if $strict_flag and (($bad | length) > 0) { exit 1 }
}

# Compare the compose config hash with the running container's
# com.docker.compose.config-hash label.
def "main diff" [
    --cntr-dir: string = ''
    --env-file: string = ''
    --include-dev
    --strict
    --quiet
]: nothing -> nothing {
    let include_dev_flag = ($include_dev or (env-flag 'CNTR_INCLUDE_DEV'))
    let strict_flag = ($strict or (env-flag 'CNTR_STRICT'))
    let root = (resolve-cntr-dir $cntr_dir)
    let stacks = (discover-stacks $root --include-dev=$include_dev_flag)
    let env_file = (resolve-env-file $env_file)

    let rows = ($stacks | each {|stack|
        let desired = (desired-hashes $stack $env_file)
        let actual_rows = (ps-rows $stack $env_file --all)
        let actual = ($actual_rows | where {|row| ($row.Service? | default '') != '' } | reduce --fold {} {|row, acc|
            let service = ($row.Service? | default '')
            let labels = ($row.Labels? | default {})
            let hash = if (($labels | describe | str starts-with 'record')) {
                $labels | get -o 'com.docker.compose.config-hash' | default ''
            } else {
                ''
            }
            $acc | upsert $service $hash
        })
        let hash_supported = (($desired | columns | length) > 0)
        let services = (($desired | columns) | append ($actual | columns) | uniq | sort)
        $services | each {|service|
            let desired_hash = ($desired | get -o $service | default '')
            let actual_hash = ($actual | get -o $service | default '')
            let state = if not $hash_supported {
                'unknown'
            } else if ($actual_hash | is-empty) {
                'missing'
            } else if ($desired_hash | is-empty) {
                'orphan'
            } else if ($desired_hash == $actual_hash) {
                'ok'
            } else {
                'drift'
            }
            {
                stack: $stack.name
                service: $service
                state: $state
                desired: (short-hash $desired_hash)
                actual: (short-hash $actual_hash)
            }
        }
    } | flatten)

    if not $quiet {
        print ($rows | table --expand)
    }

    if $strict_flag and (($rows | where {|row| $row.state != 'ok' } | length) > 0) { exit 1 }
}

def main [] {
    print 'Usage: cntr.nu <reconcile|status|diff> [--cntr-dir <dir>] [--env-file <file>] [--include-dev]'
}
