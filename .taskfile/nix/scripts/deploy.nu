#!/usr/bin/env nu

# Fleet deploy entrypoint for the three platform tracks.
#
#   nu deploy.nu routes --track <nixos-darwin|sm|hm>   # node names for Taskfile/gum
#   nu deploy.nu sm   [--node ...] [--nodes ...]       # deploy-rs + sm post-processing
#   nu deploy.nu hm   [--nodes ...] [--interactive]    # Ansible HM build/activate
#
# Node facts come from flake .#deployRoutes (lib/fleet derives driver/kind).
# Taskfiles are thin wrappers; keep all deploy shell logic here.

const RELOAD_SCRIPT = 'sudo -n systemctl reload ssh 2>/dev/null || sudo -n systemctl reload sshd 2>/dev/null || true; sudo -n systemctl restart systemd-journald; sudo -n systemctl restart systemd-logind; echo "drop-ins reloaded"'

# Resolve the dotfiles repo root from this script's directory:
# .taskfile/nix/scripts -> ../../..
def repo-root []: nothing -> path {
    $env.FILE_PWD | path join ../../.. | path expand
}

# Evaluate .#deployRoutes in the repo flake.
def load-routes [repo_root: path]: nothing -> record {
    try {
        cd $repo_root
    } catch {|err|
        error make {msg: $'failed to enter repo root ($repo_root): ($err.msg)'}
    }

    let result = (^nix eval --impure --json .#deployRoutes | complete)
    if $result.exit_code != 0 {
        error make {msg: $'failed to evaluate .#deployRoutes: ($result.stderr | str trim)'}
    }

    try {
        $result.stdout | from json
    } catch {|err|
        error make {msg: $'invalid .#deployRoutes JSON: ($err.msg)'}
    }
}

# Node names for one platform track.
def route-names [routes: record, track: string]: nothing -> list<string> {
    let nodes = match $track {
        'nixos-darwin' => (
            $routes
            | transpose name route
            | where {|row| ($row.route.driver == 'deploy-rs') and ($row.route.kind != 'sm')}
        )
        'sm' => (
            $routes
            | transpose name route
            | where {|row| ($row.route.kind == 'sm') and ($row.route.driver == 'deploy-rs')}
        )
        'hm' => (
            $routes
            | transpose name route
            | where {|row| $row.route.driver == 'ansible-hm'}
        )
        _ => (error make {msg: $'unknown deploy track: ($track)'})
    }

    $nodes | get name | sort
}

# Fetch one node's route or fail with a clear error.
def route-for [routes: record, node: string]: nothing -> record {
    let route = ($routes | get --optional $node)
    if $route == null {
        error make {msg: $'no deploy route for node: ($node)'}
    }
    $route
}

# Split a comma-separated node list. Used by Taskfile NODES=... overrides.
def split-nodes [raw: string]: nothing -> list<string> {
    $raw
    | split row ','
    | each {|node| $node | str trim }
    | where {|node| $node | is-not-empty}
}

# Interactive multi-select via gum. `available` must be a non-empty list.
def select-nodes [available: list<string>, header: string]: nothing -> list<string> {
    let selected = (
        $available
        | str join (char newline)
        | ^gum choose --no-limit --header $header
    )
    $selected
    | lines
    | each {|node| $node | str trim }
    | where {|node| $node | is-not-empty}
}

def shell-path [user: string]: nothing -> string {
    let home_dir = if $user == root { '/root' } else { $'/home/($user)' }
    $'($home_dir)/.nix-profile/bin/zsh'
}

# Build the remote shell script without interpolating shell `$` syntax.
def build-switch-script [user: string, shell_path: string]: nothing -> string {
    r#'current=$(getent passwd __USER__ | cut -d: -f7); if [ "$current" != "__SHELL_PATH__" ]; then sudo -n usermod -s "__SHELL_PATH__" __USER__; echo "shell -> zsh"; else echo "shell already zsh"; fi'#
    | str replace --all __USER__ $user
    | str replace --all __SHELL_PATH__ $shell_path
}

def sm-deploy-args [node: string]: nothing -> list<string> {
    [
        'run'
        '--impure'
        '.#deploy-rs'
        '--'
        '--skip-checks'
        $'.#($node)'
        '--'
        '--impure'
    ]
}

def build-inventory [routes: record]: nothing -> list<string> {
    $routes
    | transpose name route
    | where {|row| $row.route.driver == 'ansible-hm'}
    | each {|row|
        let port = if $row.route.port == null { '' } else { $' ansible_port=($row.route.port)' }
        $'($row.name) ansible_host=($row.route.host) ansible_user=($row.route.sshUser)($port)'
    }
}

def inventory-content [...lines: string]: nothing -> string {
    (['[hm]'] | append $lines | str join (char newline)) + (char newline)
}

def remove-temp [generated: bool, path: path]: nothing -> nothing {
    if $generated {
        try {
            rm --force $path
        } catch {|err|
            print -e $'warning: failed to remove temp inventory ($path): ($err.msg)'
        }
    }
}

# Print node names, one per line, for gum / Taskfile vars.
def "main routes" [--track: string = 'nixos-darwin']: nothing -> string {
    let routes = (load-routes (repo-root))
    route-names $routes $track | str join (char newline)
}

# Deploy one or more sm nodes, including the sm post-processing.
def "main sm" [
    --node: string = ''
    --nodes: string = ''
    --node-host: string = ''
    --node-user: string = ''
    --dry-run
]: nothing -> nothing {
    if ($node | is-not-empty) and ($nodes | is-not-empty) {
        error make {msg: 'use either --node or --nodes, not both'}
    }

    let repo_root = (repo-root)
    try {
        cd $repo_root
    } catch {|err|
        error make {msg: $'failed to enter repo root ($repo_root): ($err.msg)'}
    }
    let routes = (load-routes $repo_root)
    let explicit = (
        if ($node | is-not-empty) {
            [$node]
        } else if ($nodes | is-not-empty) {
            split-nodes $nodes
        } else {
            []
        }
    )
    let selected = (
        if ($explicit | is-not-empty) {
            $explicit
        } else {
            select-nodes (route-names $routes sm) '选择 sm-vps 节点（可多选）'
        }
    )

    if ($selected | is-empty) {
        error make {msg: 'no sm node selected'}
    }
    if (($node_host | is-not-empty) or ($node_user | is-not-empty)) and (($selected | length) != 1) {
        error make {msg: '--node-host/--node-user require exactly one sm node'}
    }

    # Validate every selected node before running any deploy-rs command.
    for node in $selected {
        let route = (route-for $routes $node)
        if $route.kind != sm {
            error make {msg: $'($node) is not an sm node, kind=($route.kind); use task nix:deploy instead'}
        }
    }

    let targets = (
        $selected | each {|node|
            let route = (route-for $routes $node)
            {
                node: $node
                host: (if ($node_host | is-not-empty) { $node_host } else { $route.host })
                user: (if ($node_user | is-not-empty) { $node_user } else { $route.sshUser })
            }
        }
    )

    for target in $targets {
        let args = (sm-deploy-args $target.node)
        let shell = (shell-path $target.user)
        let switch_script = (build-switch-script $target.user $shell)

        print $'==> deploy-rs .#($target.node) [sm + HM]'

        if $dry_run {
            print $'  would run: nix ($args | str join " ")'
            print $'  would run: ssh ($target.user)@($target.host) script=($switch_script)'
            print $'  would run: ssh ($target.user)@($target.host) script=($RELOAD_SCRIPT)'
            continue
        }

        try {
            ^nix ...$args
        } catch {|err|
            error make {msg: $'deploy-rs failed for ($target.node): ($err.msg)'}
        }

        try {
            ^ssh -o BatchMode=yes -o ConnectTimeout=15 $'($target.user)@($target.host)' $switch_script
        } catch {|err|
            error make {msg: $'shell switch failed for ($target.node): ($err.msg)'}
        }

        try {
            ^ssh -o BatchMode=yes -o ConnectTimeout=15 $'($target.user)@($target.host)' $RELOAD_SCRIPT
        } catch {|err|
            error make {msg: $'drop-in reload failed for ($target.node): ($err.msg)'}
        }
    }
}

# Apply Home Manager on selected hm nodes, or all hm nodes when --nodes is empty.
def "main hm" [
    --nodes: string = ''
    --inventory: string = ''
    --tags: string = ''
    --extra-args: string = ''
    --interactive
    --dry-run
]: nothing -> nothing {
    if (which ansible-playbook | is-empty) {
        error make {msg: 'ansible-playbook is required (enable home/base/devops/tf.nix ansible)'}
    }

    let repo_root = (repo-root)
    let routes = (load-routes $repo_root)
    let hm_nodes = (route-names $routes hm)
    let explicit = (split-nodes $nodes)
    let selected = (
        if ($explicit | is-not-empty) {
            $explicit
        } else if $interactive {
            select-nodes $hm_nodes '选择 hm 节点（可多选）'
        } else {
            $hm_nodes
        }
    )

    if $interactive and ($explicit | is-empty) and ($selected | is-empty) {
        error make {msg: 'no hm node selected'}
    }

    let missing = ($selected | where {|node| $node not-in $hm_nodes})
    if ($missing | is-not-empty) {
        error make {msg: $'not ansible-hm nodes: ($missing | str join ", ")'}
    }

    let generated = ($inventory | is-empty)
    let inv = if $generated {
        let path = (^mktemp | str trim)
        let content = (inventory-content ...(build-inventory $routes))
        try {
            $content | save --force --raw $path
        } catch {|err|
            error make {msg: $'failed to write inventory ($path): ($err.msg)'}
        }
        print '==> generated inventory:'
        print $content
        $path
    } else {
        if not ($inventory | path exists) {
            error make {msg: $'inventory not found: ($inventory)'}
        }
        $inventory
    }

    let playbook = ($repo_root | path join hosts/_base/hm/ansible/bootstrap.yml)
    let limit_args = if ($selected | is-empty) { [] } else { ['--limit' ($selected | str join ',')] }
    let tag_args = if ($tags | is-empty) { [] } else { ['--tags' $tags] }
    let extra_args = (
        if ($extra_args | is-empty) {
            []
        } else {
            $extra_args | split row ' ' | where {|arg| $arg | is-not-empty}
        }
    )
    let args = [
        '-i'
        $inv
        $playbook
        ...$limit_args
        ...$tag_args
        ...$extra_args
    ]

    if $dry_run {
        print $'  would run: ansible-playbook ($args | str join " ")'
        remove-temp $generated $inv
        return
    }

    try {
        ^ansible-playbook ...$args
    } catch {|err|
        remove-temp $generated $inv
        error make {msg: $'ansible-playbook failed: ($err.msg)'}
    }

    remove-temp $generated $inv
}

def main []: nothing -> nothing {
    print -e 'Usage: deploy.nu <routes|sm|hm> [flags]'
    exit 2
}
