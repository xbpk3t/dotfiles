#!/usr/bin/env nu

# vps-check.nu — ecs-only VPS triage
#
# fresh:   newly bought VPS; installs core deps via the distro package manager
# managed: NixOS; never installs; run through nix-shell (see Taskfile.vps.yml)
#
# Must run as root.
#
# The mihomo stop/restore uses try/finally. Ctrl-C (SIGINT) does enter finally;
# SIGTERM/SIGHUP do not, so a hard kill may require manual `systemctl start mihomo`.

const script_version = '0.4.0'

const core_cmds = [
    curl
    unzip
    ip
    free
    tar
    timeout
    ping
    bc
    jq
    tee
]

const optional_cmds = [dmidecode sysbench fio]

const proxy_env_names = [
    http_proxy
    https_proxy
    all_proxy
    HTTP_PROXY
    HTTPS_PROXY
    ALL_PROXY
]

# ── logging ────────────────────────────────────────────────────────────────

def log [msg: string]: nothing -> nothing {
    let ts = date now | format date '%Y-%m-%d %H:%M:%S'
    print $'[($ts)] ($msg)'
}

def warn [msg: string]: nothing -> nothing {
    let ts = date now | format date '%Y-%m-%d %H:%M:%S'
    print -e $'[($ts)] WARN: ($msg)'
}

def fail [msg: string]: nothing -> error {
    error make {msg: $msg}
}

def iso-now []: nothing -> string {
    date now | format date '%Y-%m-%dT%H:%M:%S%z'
}

# ── helpers ────────────────────────────────────────────────────────────────

def have [cmd: string]: nothing -> bool {
    (which $cmd | is-not-empty)
}

def missing [cmds: list<string>]: nothing -> list<string> {
    $cmds | where {|cmd| not (have $cmd) }
}

def init-report-dir [out: path]: nothing -> string {
    let base = if ($out | is-empty) {
        if (^test -w /root | complete).exit_code == 0 {
            '/root/vps-check'
        } else {
            (pwd | path join 'vps-check')
        }
    } else {
        $out | path expand
    }
    let stamp = date now | format date '%Y%m%d-%H%M%S'
    let dir = $base | path join $stamp
    let mk = (
        ^mkdir -p ($dir | path join 'artifacts') ($dir | path join 'logs')
        | complete
    )
    if $mk.exit_code != 0 {
        fail $"Failed to create report dir ($dir): ($mk.stderr | str trim)"
    }
    $dir
}

# ── proxy / TUN ────────────────────────────────────────────────────────────

def detect-proxy-env []: nothing -> list<string> {
    $proxy_env_names | each {|name|
        let val = $env | get --optional $name
        if $val == null { null } else { $"($name)=($val)" }
    } | compact
}

def hide-proxy-env []: nothing -> nothing {
    hide-env --ignore-errors ...$proxy_env_names
}

def mihomo-active [service: string]: nothing -> bool {
    (^systemctl is-active --quiet $service | complete).exit_code == 0
}

def egress-dev []: nothing -> string {
    let r = (^ip route get 1.1.1.1 | complete)
    if $r.exit_code != 0 { return '' }
    let parts = $r.stdout | split row ' '
    let idx = (
        $parts
        | enumerate
        | where {|e| $e.item == 'dev' }
        | get --optional index
        | get --optional 0
    )
    if $idx == null { return '' }
    let dev = $parts | get --optional ($idx + 1)
    if $dev == null { '' } else { $dev }
}

def tun-present [iface: string]: nothing -> bool {
    if ($iface | is-empty) { return false }
    if (^ip link show $iface | complete).exit_code == 0 { return true }
    let dev = (egress-dev)
    if ($dev | is-empty) { return false }
    ($dev == $iface) or ($dev | str starts-with 'tun')
}

def stop-proxy-stack [cfg: record]: nothing -> nothing {
    let service = $cfg.service
    let iface = $cfg.iface
    let marker = $cfg.marker

    if (mihomo-active $service) {
        log $"Stopping ($service); will restore on exit..."
        # Write the marker before stopping: finally restores even if stop crashes.
        try {
            'stopped' | save --force $marker
        } catch {|err|
            fail $"Cannot write proxy marker ($marker): ($err.msg)"
        }

        let r = (^systemctl stop $service | complete)
        if $r.exit_code != 0 {
            fail $"Failed to stop ($service): ($r.stderr | str trim)"
        }

        mut tries = 0
        while $tries < 30 and (tun-present $iface) {
            sleep 0.5sec
            $tries += 1
        }
        if (tun-present $iface) {
            fail $"TUN '($iface)' is still present after stopping ($service)."
        }

        let dev = (egress-dev)
        if (not ($dev | is-empty)) and (($dev == $iface) or ($dev | str starts-with 'tun')) {
            fail $"Default route still goes through '($dev)' after stopping ($service)."
        }
        let dev_display = if ($dev | is-empty) { 'unknown' } else { $dev }
        log $"Direct egress device: ($dev_display)"
        return
    }

    if (tun-present $iface) {
        fail $"A proxy TUN is present, but ($service) is not active; cannot stop it automatically."
    }
}

def prepare-network [cfg: record]: nothing -> nothing {
    let service = $cfg.service
    let iface = $cfg.iface

    let envs = (detect-proxy-env)
    if not ($envs | is-empty) {
        warn $"Ignoring inherited proxy env: ($envs | str join ', ')"
    }
    hide-proxy-env

    if $cfg.allow_proxy {
        warn '--allow-proxy: skipping proxy/TUN checks; results may describe the proxy egress.'
        return
    }

    if $cfg.stop_proxy {
        stop-proxy-stack $cfg
        return
    }

    if (mihomo-active $service) or (tun-present $iface) {
        fail "Transparent proxy/TUN detected; refusing to run.\nOptions:\n  sudo nu vps-check.nu --stop-proxy ...   # stop the proxy, restore on exit\n  systemctl stop mihomo                  # stop manually, then rerun\n  --allow-proxy                          # run anyway (results may be invalid)"
    }
}

# ── dependencies ───────────────────────────────────────────────────────────

def hints-fresh []: nothing -> nothing {
    let lines = [
        'Install hints:'
        '  Debian/Ubuntu: apt-get update && apt-get install -y curl unzip iproute2 procps dmidecode bc jq tar iputils-ping sysbench fio'
        '  RHEL/Fedora:   dnf install -y curl unzip iproute procps-ng dmidecode bc jq tar iputils sysbench fio'
        '  Arch:          pacman -Sy --needed --noconfirm curl unzip iproute2 procps-ng dmidecode bc jq tar iputils sysbench fio'
        '  Alpine:        apk add curl unzip iproute2 procps dmidecode bc jq tar iputils sysbench fio'
        '  NixOS:         use --profile managed and the Taskfile/nix-shell wrapper'
        '  Restricted:    pre-download goecs and use --goecs-bin <path>'
    ]
    for line in $lines { print -e $line }
}

def hints-managed [script_path: string]: nothing -> nothing {
    let run_line = $"  nix-shell -p nushell curl unzip iproute2 procps dmidecode bc jq gnutar iputils coreutils sysbench fio --run 'sudo env PATH=\"$PATH\" nu ($script_path) --profile managed --stop-proxy'"
    let lines = [
        'NixOS managed profile never installs packages. Run inside nix-shell:'
        ''
        $run_line
        ''
        'Or use the Taskfile wrapper:'
        '  task -t .taskfile/kernel/Taskfile.vps.yml default'
        ''
        'If GitHub/CDN is unreachable, pre-download goecs and add --goecs-bin <path>.'
    ]
    for line in $lines { print -e $line }
}

def install-core-deps []: nothing -> nothing {
    let pm = if (have 'apt-get') {
        {
            kind: 'apt'
            pkgs: [
                curl
                unzip
                iproute2
                procps
                bc
                jq
                tar
                iputils-ping
            ]
            env: {DEBIAN_FRONTEND: 'noninteractive'}
        }
    } else if (have 'dnf') {
        {
            kind: 'dnf'
            pkgs: [
                curl
                unzip
                iproute
                procps-ng
                bc
                jq
                tar
                iputils
            ]
            env: {}
        }
    } else if (have 'yum') {
        {
            kind: 'yum'
            pkgs: [
                curl
                unzip
                iproute
                procps-ng
                bc
                jq
                tar
                iputils
            ]
            env: {}
        }
    } else if (have 'pacman') {
        {
            kind: 'pacman'
            pkgs: [
                curl
                unzip
                iproute2
                procps-ng
                bc
                jq
                tar
                iputils
            ]
            env: {}
        }
    } else if (have 'apk') {
        {
            kind: 'apk'
            pkgs: [
                curl
                unzip
                iproute2
                procps
                bc
                jq
                tar
                iputils
            ]
            env: {}
        }
    } else if (have 'zypper') {
        {
            kind: 'zypper'
            pkgs: [
                curl
                unzip
                iproute2
                procps
                bc
                jq
                tar
                iputils
            ]
            env: {}
        }
    } else {
        null
    }

    if $pm == null {
        hints-fresh
        fail 'No supported package manager found.'
    }

    log $"Installing core dependencies: ($pm.pkgs | str join ' ')"
    if $pm.kind == 'apt' {
        let upd = (
            with-env $pm.env { ^apt-get update -y | complete }
        )
        if $upd.exit_code != 0 {
            warn 'apt-get update failed; continuing.'
        }
    }

    let result = match $pm.kind {
        'apt' => (
            with-env $pm.env { ^apt-get install -y ...$pm.pkgs | complete }
        )
        'dnf' => (^dnf install -y ...$pm.pkgs | complete)
        'yum' => (^yum install -y ...$pm.pkgs | complete)
        'pacman' => (^pacman -Sy --needed --noconfirm ...$pm.pkgs | complete)
        'apk' => (^apk add ...$pm.pkgs | complete)
        'zypper' => (^zypper install -y ...$pm.pkgs | complete)
        _ => (fail 'Unsupported package manager.')
    }
    if $result.exit_code != 0 {
        hints-fresh
        fail $"Core dependency installation failed: ($result.stderr | str trim)"
    }

    log 'Installing optional hardware tools (best effort): dmidecode sysbench fio'
    let opt = match $pm.kind {
        'apt' => (
            with-env $pm.env { ^apt-get install -y dmidecode sysbench fio | complete }
        )
        'dnf' => (^dnf install -y dmidecode sysbench fio | complete)
        'yum' => (^yum install -y dmidecode sysbench fio | complete)
        'pacman' => (^pacman -Sy --needed --noconfirm dmidecode sysbench fio | complete)
        'apk' => (^apk add dmidecode sysbench fio | complete)
        'zypper' => (^zypper install -y dmidecode sysbench fio | complete)
        _ => (fail 'Unsupported package manager.')
    }
    if $opt.exit_code != 0 {
        warn 'Optional tools failed; ecs will skip some hardware sections.'
    }
}

def ensure-deps [cfg: record]: nothing -> nothing {
    mut req = (missing $core_cmds)
    if $cfg.profile == 'fresh' and (not ($req | is-empty)) and (not $cfg.no_install) {
        install-core-deps
        $req = (missing $core_cmds)
    }
    if not ($req | is-empty) {
        if $cfg.profile == 'fresh' {
            hints-fresh
        } else {
            hints-managed $cfg.script_path
        }
        fail $"Missing required dependencies: ($req | str join ' ')"
    }

    let opt = (missing $optional_cmds)
    if not ($opt | is-empty) {
        warn $"Optional hardware tools missing: ($opt | str join ' ')"
        warn 'ecs will still run, but CPU/memory/disk sections may be thinner.'
    }
}

# ── ecs ────────────────────────────────────────────────────────────────────

def direct-ip []: nothing -> string {
    for url in [https://api.ipify.org https://ifconfig.me/ip https://ipv4.icanhazip.com] {
        let r = (
            ^curl -fsS --noproxy '*' --connect-timeout 10 --max-time 30 $url
            | complete
        )
        if $r.exit_code == 0 {
            let ip = $r.stdout | str trim
            if not ($ip | is-empty) { return $ip }
        }
    }
    ''
}

def download [url: string, dest: path]: nothing -> nothing {
    let r = (
        ^curl -fsSL --noproxy '*' --connect-timeout 10 --max-time 60 $url -o $dest
        | complete
    )
    if $r.exit_code != 0 {
        fail $"Failed to download ($url): ($r.stderr | str trim)"
    }
    if not ($dest | path exists) {
        fail $"Download did not create ($dest)"
    }
}

def ecs-install-url [flavor: string]: nothing -> string {
    match $flavor {
        'raw' => 'https://raw.githubusercontent.com/oneclickvirt/ecs/master/goecs.sh'
        'cdn' => 'https://cdn.spiritlhl.net/https://raw.githubusercontent.com/oneclickvirt/ecs/master/goecs.sh'
        'cnb' => 'https://cnb.cool/oneclickvirt/ecs/-/git/raw/main/goecs.sh'
        _ => 'https://bash.spiritlhl.net/goecs'
    }
}

def run-ecs [cfg: record]: nothing -> record {
    let report_dir = $cfg.report_dir
    let out_txt = $report_dir | path join 'ecs.txt'
    let out_log = $report_dir | path join 'logs/ecs.log'
    let workdir = $report_dir | path join 'artifacts/ecs'
    let mk = (^mkdir -p $workdir | complete)
    if $mk.exit_code != 0 {
        fail $"Failed to create ($workdir): ($mk.stderr | str trim)"
    }

    mut source = 'installed'
    mut goecs = ''

    if not ($cfg.goecs_bin | is-empty) {
        $goecs = ($cfg.goecs_bin | path expand)
        let x = (^test -x $goecs | complete)
        if $x.exit_code != 0 {
            fail $"goecs binary is not executable: ($goecs)"
        }
        $source = 'provided'
        log $"==> [ecs] using provided binary: ($goecs)"
    } else {
        let installer = $workdir | path join 'goecs.sh'
        log $"==> [ecs] downloading installer ($cfg.flavor)"
        download (ecs-install-url $cfg.flavor) $installer
        let chmod = (^chmod +x $installer | complete)
        if $chmod.exit_code != 0 {
            fail $"Cannot chmod ($installer): ($chmod.stderr | str trim)"
        }

        log '==> [ecs] installing goecs'
        let inst = (do {
            try {
                cd $workdir
            } catch {|err|
                fail $"Cannot cd to ($workdir): ($err.msg)"
            }
            with-env { noninteractive: 'true' } { ^bash ./goecs.sh install | complete }
        })
        try {
            $inst.stdout | save --append $out_log
        } catch {|err|
            warn $"Cannot write ($out_log): ($err.msg)"
        }
        try {
            $inst.stderr | save --append $out_log
        } catch {|err|
            warn $"Cannot write ($out_log): ($err.msg)"
        }
        if $inst.exit_code != 0 {
            warn 'If GitHub/CDN is unreachable, pre-download goecs and use --goecs-bin <path>.'
            fail $"ecs installer failed; see ($out_log)"
        }

        let candidates = [
            ($workdir | path join 'goecs')
            '/usr/local/bin/goecs'
            '/usr/bin/goecs'
        ]
        let found = $candidates | where {|p| $p | path exists } | get --optional 0
        $goecs = if $found != null {
            $found
        } else {
            let w = which goecs | get --optional path | get --optional 0
            if $w == null {
                fail $"goecs binary not found after install; see ($out_log)"
            }
            $w
        }
        $source = 'installed'
    }

    let goecs_cmd = $goecs
    let ver = (^timeout 5 $goecs_cmd -v command | complete)
    let version = if $ver.exit_code == 0 {
        $ver.stdout | str trim
    } else {
        'unknown'
    }
    log $"goecs: ($version)"

    let args = [
        '-menu=false'
        $'-upload=($cfg.upload)'
        '-l'
        $cfg.lang
        '-ping=true'
        '-web=true'
        '-tgdc=true'
        '-backtrace=true'
        '-security=true'
        '-email=true'
        '-speed=true'
        '-nt3=true'
    ] ++ $cfg.extra_args

    log $"==> [ecs] running; output=($out_txt)"
    do {
        try {
            cd $workdir
        } catch {|err|
            fail $"Cannot cd to ($workdir): ($err.msg)"
        }
        with-env { noninteractive: 'true' } {
            ^timeout --preserve-status $cfg.timeout $goecs_cmd ...$args
        }
    } o+e>| ^tee $out_txt | ^tee --append $out_log | print

    let content = if ($out_txt | path exists) {
        try {
            open --raw $out_txt | ansi strip
        } catch {
            ''
        }
    } else {
        ''
    }
    let ok = $content | str contains '测试结果已写入'
    if not $ok {
        warn $"ecs failed or produced no completion marker; see ($out_log)"
    }

    let link = (
        $content
        | parse -r '(?P<url>https://paste\.spiritlhl\.net/#/show/[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)?)'
        | get --optional url
        | get --optional 0
    )
    let link_str = if $link == null { '' } else { $link }
    if $cfg.upload and ($link_str | is-empty) {
        warn 'ecs upload was requested but no paste link was captured.'
    }

    {
        ok: $ok
        link: $link_str
        source: $source
        version: $version
    }
}

# ── summary ────────────────────────────────────────────────────────────────

def write-summary [cfg: record]: nothing -> nothing {
    let report_dir = $cfg.report_dir
    let ecs_txt = $report_dir | path join 'ecs.txt'
    let content = if ($ecs_txt | path exists) {
        try {
            open --raw $ecs_txt | ansi strip
        } catch {
            ''
        }
    } else {
        ''
    }

    let vline = (
        $content
        | lines
        | where {|line| $line =~ '版本' }
        | get --optional 0
    )
    let version = if $vline == null {
        'unknown'
    } else {
        $vline | str replace -r '^\s*版本[：:]\s*' ''
    }

    let link = (
        $content
        | parse -r '(?P<url>https://paste\.spiritlhl\.net/#/show/[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)?)'
        | get --optional url
        | get --optional 0
    )
    let link_str = if $link == null { '' } else { $link }

    let proxy_line = if $cfg.outcome.proxy_stopped? == true {
        $"  proxy: ($env.PROXY_SERVICE? | default 'mihomo') stopped during run; restored on exit"
    } else if $cfg.allow_proxy {
        '  proxy: --allow-proxy (results may describe proxy egress)'
    } else {
        '  proxy: direct'
    }

    let egress_display = if ($cfg.outcome.egress_ip? | is-empty) { 'unknown' } else { $cfg.outcome.egress_ip? }
    let lines = [
        'vps-check summary (ecs-only)'
        $"  script_version: ($script_version)"
        $"  profile: ($cfg.profile)"
        $"  host: (^hostname | str trim)"
        $"  report_dir: ($report_dir)"
        $"  started: ($cfg.started)"
        $"  finished: (iso-now)"
        $"  elapsed_secs: ($cfg.elapsed)"
        '  run_as_root: yes'
        $proxy_line
        $"  egress_ip: ($egress_display)"
        $"  ecs_version: ($version)"
        $"  goecs_source: ($cfg.outcome.source? | default 'unknown')"
        (
            if ($cfg.outcome.goecs_bin? | is-empty) { null } else { $"  goecs_bin: ($cfg.outcome.goecs_bin?)" }
        )
        ''
        'Report link:'
        (
            if ($link_str | is-empty) { '  (none captured)' } else { $"  ecs: ($link_str)" }
        )
        $"Report file: ($ecs_txt)"
        ''
        $"Logs: ($report_dir | path join 'logs')"
    ] | compact

    let summary = $report_dir | path join 'summary.txt'
    try {
        $lines | save --force $summary
    } catch {|err|
        fail $"Cannot write summary ($summary): ($err.msg)"
    }
}

# ── CLI ────────────────────────────────────────────────────────────────────

def main [
    --profile: string = 'auto'      # auto | fresh | managed
    --fresh                         # shortcut for --profile fresh
    --managed                       # shortcut for --profile managed
    --out: path = ''                # output base (default: /root/vps-check or ./vps-check)
    --timeout: int = 1800           # hard timeout for ecs, seconds
    --lang: string = 'zh'           # ecs language: zh | en
    --upload                        # upload ecs report (default)
    --no-upload                     # do not upload ecs report
    --no-install                    # fresh: do not install dependencies
    --stop-proxy                    # stop mihomo, restore on exit/finally
    --allow-proxy                   # run even with TUN/proxy (results may be invalid)
    --goecs-bin: path = ''          # use a pre-downloaded goecs binary
    --ecs-install: string = 'short' # short | raw | cdn | cnb
    --ecs-args: string = ''         # extra args passed to goecs
    --version (-V)                  # print version
]: nothing -> nothing {
    if $version {
        print $"vps-check.nu ($script_version)"
        return
    }

    if $upload and $no_upload { fail '--upload and --no-upload are mutually exclusive.' }
    if $stop_proxy and $allow_proxy { fail '--stop-proxy and --allow-proxy are mutually exclusive.' }
    if $fresh and $managed { fail '--fresh and --managed are mutually exclusive.' }
    if $timeout <= 0 { fail '--timeout must be a positive integer.' }
    if $lang not-in ['zh' 'en'] { fail '--lang must be zh or en.' }
    if $ecs_install not-in ['short' 'raw' 'cdn' 'cnb'] {
        fail '--ecs-install must be short|raw|cdn|cnb.'
    }

    let uid = (^id -u | str trim | into int)
    if $uid != 0 {
        fail 'vps-check must run as root (sudo nu vps-check.nu ...).'
    }

    let selected_profile = if $fresh {
        'fresh'
    } else if $managed {
        'managed'
    } else if $profile == 'auto' {
        if ('/etc/NIXOS' | path exists) { 'managed' } else { 'fresh' }
    } else {
        $profile
    }
    if $selected_profile not-in ['fresh' 'managed'] {
        fail $"Invalid profile: ($selected_profile); expected auto|fresh|managed."
    }

    let upload = (not $no_upload)
    let script_path = $env.CURRENT_FILE? | default 'vps-check.nu'
    let extra_args = if ($ecs_args | is-empty) {
        []
    } else {
        $ecs_args | split row ' ' | where {|arg| not ($arg | is-empty) }
    }
    let selected_goecs = if ($goecs_bin | is-empty) {
        ''
    } else {
        let p = $goecs_bin | path expand
        if not ($p | path exists) { fail $"goecs binary not found: ($p)" }
        let x = (^test -x $p | complete)
        if $x.exit_code != 0 { fail $"goecs binary is not executable: ($p)" }
        $p
    }

    log $"Profile: ($selected_profile)"
    let report_dir = (init-report-dir $out)
    log $"Report dir: ($report_dir)"

    let proxy_service = $env.PROXY_SERVICE? | default 'mihomo'
    let proxy_iface = $env.PROXY_TUN_IFACE? | default 'Meta'
    let proxy_marker = $report_dir | path join '.proxy-stopped'
    let started = (iso-now)
    let start = (date now)

    let outcome = (try {
        prepare-network {
            stop_proxy: $stop_proxy
            allow_proxy: $allow_proxy
            service: $proxy_service
            iface: $proxy_iface
            marker: $proxy_marker
        }
        ensure-deps {
            profile: $selected_profile
            no_install: $no_install
            script_path: $script_path
        }

        let egress_ip = (direct-ip)
        if ($egress_ip | is-empty) {
            warn 'Could not determine the egress IP.'
        } else {
            let dev = (egress-dev)
            let dev_display = if ($dev | is-empty) { 'unknown' } else { $dev }
            log $"Egress IP: ($egress_ip); device=($dev_display)"
        }

        let ecs_result = (run-ecs {
            report_dir: $report_dir
            upload: $upload
            lang: $lang
            timeout: $timeout
            goecs_bin: $selected_goecs
            flavor: $ecs_install
            extra_args: $extra_args
        })
        {
            ok: $ecs_result.ok
            link: $ecs_result.link
            source: $ecs_result.source
            version: $ecs_result.version
            goecs_bin: $selected_goecs
            egress_ip: $egress_ip
            proxy_stopped: ($proxy_marker | path exists)
        }
    } catch {|err|
        print -e $"ERROR: ($err.msg)"
        {
            ok: false
            link: ''
            source: 'unknown'
            version: 'unknown'
            goecs_bin: $selected_goecs
            egress_ip: ''
            proxy_stopped: ($proxy_marker | path exists)
        }
    } finally {
        if ($proxy_marker | path exists) {
            log $"Restoring ($proxy_service)..."
            let r = (^systemctl start $proxy_service | complete)
            if $r.exit_code != 0 {
                warn $"Failed to restore ($proxy_service); start it manually."
            }
            try { rm --force $proxy_marker } catch {|err| warn $"Cannot remove ($proxy_marker): ($err.msg)" }
        }
    })

    let elapsed = (((date now) - $start) | into int) / 1_000_000_000 | math floor | into int
    write-summary {
        report_dir: $report_dir
        profile: $selected_profile
        started: $started
        elapsed: $elapsed
        outcome: $outcome
        allow_proxy: $allow_proxy
    }

    print ''
    log $"Done in ($elapsed)s. Report dir: ($report_dir)"
    log $"Summary: ($report_dir | path join summary.txt)"
    if not $outcome.ok {
        warn $"ecs failed. Check ($report_dir | path join logs/ecs.log)"
        exit 1
    }
}
