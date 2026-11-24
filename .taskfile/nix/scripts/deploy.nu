#!/usr/bin/env nu

# Fleet deploy entrypoint for the three platform tracks.
#
#   nu deploy.nu routes --track <nixos-darwin|sm|hm>   # node names for Taskfile/gum
#   nu deploy.nu sm   [--node ...] [--nodes ...]       # deploy-rs + sm post-processing
#   nu deploy.nu hm   [--nodes ...] [--interactive]    # Ansible HM build/activate
#
# Node facts come from flake .#deployRoutes (lib/fleet derives driver/kind).
# Taskfiles are thin wrappers; keep all deploy shell logic here.

const RELOAD_SCRIPT = 'set -e; sudo -n systemctl reload ssh 2>/dev/null || sudo -n systemctl reload sshd 2>/dev/null || true; sudo -n systemctl restart systemd-journald; sudo -n systemctl restart systemd-logind; echo "drop-ins reloaded"'

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

# Auto-deploy revision: CI provides GITHUB_SHA; local falls back to git HEAD.
def desired-revision []: nothing -> string {
    let env_rev = ($env | get --optional GITHUB_SHA | default '')
    if ($env_rev | is-not-empty) {
        $env_rev
    } else {
        ^git rev-parse HEAD | str trim
    }
}

def git-clean []: nothing -> bool {
    ^git status --porcelain | str trim | is-empty
}

# SSH args shared by pre-check and sm post-processing, matching deploy-rs.
# Keepalive 防止 TCP 半开/远端卡住时 ConnectTimeout 之后仍然永久挂起。
def ssh-route-args [route: record]: nothing -> list<string> {
    let opts = ($route | get --optional sshOpts | default null)
    let route_opts = (
        if $opts != null {
            $opts
        } else {
            let port = ($route | get --optional port | default null)
            if $port == null { [] } else { ['-p' ($port | into string)] }
        }
    )
    ['-o' 'ServerAliveInterval=15' '-o' 'ServerAliveCountMax=3'] ++ $route_opts
}

# sm track invariant: deploy-rs 之后必须修登录 shell + reload drop-in，并写下
# marker 让下一次 auto 只在“部署 + 后处理都成功”时跳过。
# main sm 和 deploy-one 共用这一份实现，避免两条路径漂移。
def sm-postprocess [route: record, host: string, user: string]: nothing -> record {
    let target = $'($user)@($host)'
    let route_args = (ssh-route-args $route)

    let switch_script = (build-switch-script $user (shell-path $user))
    let shell_result = (^ssh -o BatchMode=yes -o ConnectTimeout=15 ...$route_args $target $switch_script | complete)
    if $shell_result.exit_code != 0 {
        let output = if ($shell_result.stderr | is-empty) { $shell_result.stdout } else { $shell_result.stderr }
        return {ok: false, stage: 'shell', exit_code: $shell_result.exit_code, tail: ($output | lines | last 20 | str join (char newline))}
    }

    let reload_result = (^ssh -o BatchMode=yes -o ConnectTimeout=15 ...$route_args $target $RELOAD_SCRIPT | complete)
    if $reload_result.exit_code != 0 {
        let output = if ($reload_result.stderr | is-empty) { $reload_result.stdout } else { $reload_result.stderr }
        return {ok: false, stage: 'reload', exit_code: $reload_result.exit_code, tail: ($output | lines | last 20 | str join (char newline))}
    }

    # Marker == 远端实际激活的 system closure；下次 auto 用它判断后处理是否完成。
    let marker_script = 'sys=$(readlink -f /nix/var/nix/profiles/system 2>/dev/null || true); mkdir -p ~/.local/state/deploy && printf "%s" "$sys" > ~/.local/state/deploy/sm-postprocessed'
    let marker_result = (^ssh -o BatchMode=yes -o ConnectTimeout=15 ...$route_args $target $marker_script | complete)
    if $marker_result.exit_code != 0 {
        let output = if ($marker_result.stderr | is-empty) { $marker_result.stdout } else { $marker_result.stderr }
        return {ok: false, stage: 'marker', exit_code: $marker_result.exit_code, tail: ($output | lines | last 20 | str join (char newline))}
    }

    {ok: true, stage: 'done', exit_code: 0, tail: ''}
}

# Evaluate a store path from the local flake (no build).
def eval-store-path [expr: string]: nothing -> string {
    let result = (^nix eval --impure --raw $expr | complete)
    if $result.exit_code != 0 {
        error make {msg: $'failed to evaluate ($expr): ($result.stderr | str trim)'}
    }
    $result.stdout | str trim
}

# Desired profile paths for a node. These are exactly what deploy-rs sets via
# `nix-env --set` (the activatable wrapper), not the raw system toplevel.
# Closure path is a stronger identity than commit SHA: docs-only commits
# produce the same profile and should skip.
def desired-closure [name: string, kind: string]: nothing -> record {
    let system = eval-store-path $'.#deploy.nodes.($name).profiles.system.path.outPath'
    let home = if $kind == 'sm' {
        eval-store-path $'.#deploy.nodes.($name).profiles.home.path.outPath'
    } else {
        $system
    }
    # postprocess is the marker written after sm shell/reload succeeds.
    {system: $system, home: $home, postprocess: $system}
}

# Read currently deployed closure paths from one target.
# NixOS: /nix/var/nix/profiles/system.
# sm: system profile + standalone HM profile (profile name is `home`).
def target-closure [route: record]: nothing -> record {
    let target = $'($route.sshUser)@($route.host)'
    let command = match $route.kind {
        'nixos' => 'readlink -f /nix/var/nix/profiles/system 2>/dev/null || true'
        'sm' => 'user=$(id -un); probe() { p="$1"; if [ -e "$p" ] || [ -L "$p" ]; then readlink -f "$p" 2>/dev/null && return 0; fi; return 1; }; home=$(probe "/nix/var/nix/profiles/per-user/$user/home" || probe "/nix/var/nix/profiles/per-user/$user/home-manager" || probe "$HOME/.local/state/nix/profiles/home" || probe "$HOME/.local/state/nix/profiles/home-manager" || true); sys=$(readlink -f /nix/var/nix/profiles/system 2>/dev/null || true); marker=$(cat ~/.local/state/deploy/sm-postprocessed 2>/dev/null || true); printf "%s\n---\n%s\n---\n%s\n" "$sys" "$home" "$marker"'
        _ => ''
    }

    if ($command | is-empty) {
        return {system: '', home: '', postprocess: ''}
    }

    let route_args = (ssh-route-args $route)
    let result = (^ssh -o BatchMode=yes -o ConnectTimeout=15 ...$route_args $target $command | complete)
    if $result.exit_code != 0 {
        # 不可达时返回 unknown：让调用方尝试部署，并让 deploy-rs 报真实错误。
        return {system: 'unknown', home: 'unknown', postprocess: 'unknown'}
    }

    if $route.kind == 'sm' {
        let parts = ($result.stdout | split row '---')
        let system = (if ($parts | length) > 0 { $parts.0 | str trim } else { '' })
        let home = (if ($parts | length) > 1 { $parts.1 | str trim } else { '' })
        let postprocess = (if ($parts | length) > 2 { $parts.2 | str trim } else { '' })
        {system: $system, home: $home, postprocess: $postprocess}
    } else {
        let path = ($result.stdout | str trim)
        {system: $path, home: $path, postprocess: ''}
    }
}

def already-at [route: record, current: record, desired: record]: nothing -> bool {
    if $route.kind == 'sm' {
        ($current.system == $desired.system)
        and ($current.home == $desired.home)
        and ($current.postprocess == $desired.postprocess)
    } else if $route.kind == 'nixos' {
        $current.system == $desired.system
    } else {
        false
    }
}

def deploy-one [node: string, route: record, log_dir: path]: nothing -> record {
    let log_file = ($log_dir | path join $'($node).log')
    let base = {
        node: $node
        kind: $route.kind
        host: $route.host
        log: ($log_file | into string)
    }
    # 不要给 deploy-rs 传 --log-dir：该参数会原样拼进远端 activate-rs 命令，
    # 本地绝对路径会在目标机上创建同名目录，artifact 也收不到远端日志。
    # 这里捕获本地 deploy-rs 的完整输出，写进 workspace 下的日志文件。
    let args = [
        'run'
        '--impure'
        '.#deploy-rs'
        '--'
        '--skip-checks'
        '--no-progress'
        $'.#($node)'
        '--'
        '--impure'
    ]
    let result = (^nix ...$args | complete)
    let output = ($'($result.stdout)\n($result.stderr)' | str trim)
    try {
        $output | save --force $log_file
    } catch {|err|
        print -e $'warning: failed to write deploy log ($log_file): ($err.msg)'
    }
    if $result.exit_code != 0 {
        return ($base | merge {
            result: 'failed'
            exit_code: $result.exit_code
            tail: ($output | lines | last 20 | str join (char newline))
        })
    }

    # sm track invariant: deploy-rs 之后必须修登录 shell + reload drop-in。
    # 与 main sm 共用 sm-postprocess，避免两条路径漂移。
    if $route.kind == 'sm' {
        let post = (sm-postprocess $route $route.host $route.sshUser)
        if not $post.ok {
            return ($base | merge {
                result: 'failed'
                exit_code: $post.exit_code
                tail: ($'sm ($post.stage) failed: ' + $post.tail)
            })
        }
    }

    $base | merge {
        result: 'ok'
        exit_code: 0
        tail: ''
    }
}

def render-summary [summary: record]: nothing -> string {
    let header = [
        $'# Deploy summary — ($summary.status)'
        ''
        $'- desired revision: `($summary.desired_revision)`'
        $'- generated: ($summary.generated_at)'
        $'- dry run: ($summary.dry_run)'
        $'- dirty worktree: ($summary.dirty)'
        $'- skipped: ($summary.skipped | length)'
        $'- deployed: ($summary.results | length)'
    ]
    let host_lines = if ($summary.results | is-empty) {
        []
    } else {
        [
            ''
            '## Hosts'
            ''
            '| node | kind | host | result | before | desired | log |'
            '|---|---|---|---|---|---|---|'
        ] | append ($summary.results | each {|r|
            $'| ($r.node) | ($r.kind) | ($r.host) | ($r.result) | ($r.before_system) | ($r.desired_system) | ($r.log) |'
        })
    }
    let skipped_lines = if ($summary.skipped | is-empty) {
        []
    } else {
        [
            ''
            '## Skipped'
            ''
            '| node | reason | current system | desired system |'
            '|---|---|---|---|'
        ] | append ($summary.skipped | each {|s|
            $'| ($s.node) | ($s.reason) | ($s.current_system) | ($s.desired_system) |'
        })
    }
    let failures = ($summary.results | where {|r| $r.result == 'failed'})
    let failure_lines = if ($failures | is-empty) {
        []
    } else {
        [
            ''
            '## Failures'
            ''
        ] | append ($failures | each {|r|
            [$'### ($r.node)' '```' ($r.tail | default '') '```'] | str join (char newline)
        })
    }
    $header | append $host_lines | append $skipped_lines | append $failure_lines | str join (char newline)
}

# Deploy every deploy.auto=true node in parallel; skip hosts already at the desired profile.
def "main auto" [
    --desired-revision: string = ''
    --concurrency: int = 4
    --log-dir: string = 'deploy-logs'
    --summary-json: string = 'deploy-summary.json'
    --summary-md: string = 'deploy-summary.md'
    --allow-dirty
    --dry-run
]: nothing -> nothing {
    let repo_root = (repo-root)
    try {
        cd $repo_root
    } catch {|err|
        error make {msg: $'failed to enter repo root ($repo_root): ($err.msg)'}
    }

    let revision = (
        if ($desired_revision | is-not-empty) {
            $desired_revision
        } else {
            desired-revision
        }
    )
    let dirty = (not (git-clean))
    if (not $allow_dirty) and $dirty {
        error make {msg: 'auto deploy requires a clean working tree; commit first or use --allow-dirty for a local dry run'}
    }
    if $dirty and (not $dry_run) {
        print -e 'warning: deploying from a dirty working tree; summary records dirty=true'
    }
    if ($desired_revision | is-not-empty) and ($revision != (^git rev-parse HEAD | str trim)) {
        error make {msg: $'--desired-revision ($revision) does not match HEAD; refusing to record a misleading revision'}
    }

    let routes = (load-routes $repo_root)
    # 只接受 deploy-rs 节点；driver 过滤是 Nix 侧 test-deploy-auto-deploy-rs 之外的运行时兜底。
    let auto_rows = (
        $routes
        | transpose name route
        | where {|row| ($row.route | get --optional auto | default false) and (($row.route | get --optional driver | default '') == 'deploy-rs') }
    )
    if ($auto_rows | is-empty) {
        print 'no deploy.auto nodes'
        let summary = {
            status: 'success'
            desired_revision: $revision
            generated_at: (date now | format date '%Y-%m-%dT%H:%M:%S%z')
            dry_run: $dry_run
            dirty: $dirty
            skipped: []
            results: []
        }
        try {
            $summary | to json --indent 2 | save --force $summary_json
        } catch {|err|
            error make {msg: $'failed to write summary JSON ($summary_json): ($err.msg)'}
        }
        try {
            render-summary $summary | save --force $summary_md
        } catch {|err|
            error make {msg: $'failed to write summary Markdown ($summary_md): ($err.msg)'}
        }
        return
    }

    let log_dir = ($repo_root | path join $log_dir | path expand)
    if not ($log_dir | path exists) {
        try {
            mkdir $log_dir
        } catch {|err|
            error make {msg: $'failed to create log dir ($log_dir): ($err.msg)'}
        }
    }

    print $'==> desired revision: ($revision)'
    print $'==> auto nodes: ($auto_rows | get name | str join ", ")'

    let checked = ($auto_rows | each {|row|
        let current = (target-closure $row.route)
        let desired = (
            try {
                desired-closure $row.name $row.route.kind
            } catch {|err|
                {system: '', home: '', error: ($err.msg | str trim)}
            }
        )
        let desired_error = ($desired | get --optional error | default '')
        {
            name: $row.name
            route: $row.route
            current: $current
            desired: $desired
            desired_error: $desired_error
            skip: (if ($desired_error | is-empty) { already-at $row.route $current $desired } else { false })
        }
    })
    let skipped = ($checked | where {|row| $row.skip})
    let selected = ($checked | where {|row| not $row.skip})

    print $'==> skip: ($skipped | length), deploy: ($selected | length)'
    for row in $skipped {
        print $'  skip ($row.name): already at desired profile'
    }
    for row in $selected {
        if ($row.desired_error | is-not-empty) {
            print -e $'  error ($row.name): ($row.desired_error)'
        } else {
            print $'  deploy ($row.name): ($row.current.system) -> ($row.desired.system)'
        }
    }

    let results = (
        if $dry_run {
            $selected | each {|row|
                if ($row.desired_error | is-not-empty) {
                    {
                        node: $row.name
                        kind: $row.route.kind
                        host: $row.route.host
                        result: 'failed'
                        exit_code: null
                        log: ''
                        before_system: $row.current.system
                        desired_system: ''
                        tail: $row.desired_error
                    }
                } else {
                    {
                        node: $row.name
                        kind: $row.route.kind
                        host: $row.route.host
                        result: 'would-deploy'
                        exit_code: null
                        log: ''
                        before_system: $row.current.system
                        desired_system: $row.desired.system
                        tail: ''
                    }
                }
            }
        } else if ($selected | is-empty) {
            []
        } else {
            let threads = if $concurrency < 1 { 1 } else { $concurrency }
            $selected | par-each --threads $threads {|row|
                if ($row.desired_error | is-not-empty) {
                    {
                        node: $row.name
                        kind: $row.route.kind
                        host: $row.route.host
                        result: 'failed'
                        exit_code: null
                        log: ''
                        before_system: $row.current.system
                        desired_system: ''
                        tail: $row.desired_error
                    }
                } else {
                    deploy-one $row.name $row.route $log_dir | merge {
                        before_system: $row.current.system
                        desired_system: $row.desired.system
                    }
                }
            } | sort-by node
        }
    )
    let failed = ($results | where {|row| $row.result == 'failed'})

    let summary = {
        status: (if ($failed | is-empty) { 'success' } else { 'failed' })
        desired_revision: $revision
        generated_at: (date now | format date '%Y-%m-%dT%H:%M:%S%z')
        dry_run: $dry_run
        dirty: $dirty
        skipped: ($skipped | each {|row| {
            node: $row.name
            reason: 'already-at-closure'
            current_system: $row.current.system
            current_home: $row.current.home
            desired_system: $row.desired.system
            desired_home: $row.desired.home
        }})
        results: $results
    }

    try {
        $summary | to json --indent 2 | save --force $summary_json
    } catch {|err|
        error make {msg: $'failed to write summary JSON ($summary_json): ($err.msg)'}
    }
    try {
        render-summary $summary | save --force $summary_md
    } catch {|err|
        error make {msg: $'failed to write summary Markdown ($summary_md): ($err.msg)'}
    }
    print $'==> summary: ($summary_json)'

    if not ($failed | is-empty) {
        print -e $'deploy failed on: ($failed | get node | str join ", ")'
        exit 1
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
                route: $route
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
            print $'  would run: ssh ($target.user)@($target.host) marker write'
            continue
        }

        try {
            ^nix ...$args
        } catch {|err|
            error make {msg: $'deploy-rs failed for ($target.node): ($err.msg)'}
        }

        let post = (sm-postprocess $target.route $target.host $target.user)
        if not $post.ok {
            error make {msg: $'sm ($post.stage) failed for ($target.node): ($post.tail)'}
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
    print -e 'Usage: deploy.nu <routes|sm|hm|auto> [flags]'
    exit 2
}
