#!/usr/bin/env nu

# 读取并校验 apps manifest。
def load-apps-config [config_path: string]: nothing -> record {
    let config_abs = ($config_path | path expand)

    if not ($config_abs | path exists) {
        error make {
            msg: $'Config file not found: ($config_abs)'
        }
    }

    let config = (open $config_abs)

    if (($config | describe) != 'record') {
        error make {
            msg: $'Invalid apps config: ($config_abs)'
        }
    }

    {
        fdroid: ($config.fdroid? | default [])
        manual: ($config.manual? | default [])
    }
}

def normalize-debloat-group [
    items: any
    action_name: string
    config_abs: string
]: nothing -> list<record> {
    let items_type = ($items | describe)

    # 重要：grouped debloat config 下，每个 action key 的值必须仍然是数组。
    # 这里同时接受 `list<...>` 与 `table<...>`，避免 Nushell 对 YAML 的解析差异导致误判。
    if not (
        ($items_type | str starts-with 'list<')
        or ($items_type | str starts-with 'table<')
    ) {
        error make {
            msg: $'Invalid debloat group in config: ($config_abs)'
            help: $'Expected array under action key `($action_name)`, got: ($items_type)'
        }
    }

    $items | each {|item|
        let item_type = ($item | describe)

        if not ($item_type | str starts-with 'record') {
            error make {
                msg: $'Invalid debloat item in config: ($config_abs)'
                help: $'Expected record in action key `($action_name)`, got: ($item_type)'
            }
        }

        let package_name = ($item.pkg? | default '' | str trim)
        if $package_name == '' {
            error make {
                msg: $'Missing pkg field in debloat config: ($config_abs)'
                help: $'Action key `($action_name)` contains item without pkg: ($item | to nuon)'
            }
        }

        {
            pkg: $package_name
            act: $action_name
            des: ($item.des? | default '')
        }
    }
}

# 读取并校验 debloat manifest。
def load-debloat-config [config_path: string]: nothing -> list<record> {
    let config_abs = ($config_path | path expand)

    if not ($config_abs | path exists) {
        error make {
            msg: $'Config file not found: ($config_abs)'
        }
    }

    let config = (open $config_abs)
    let config_type = ($config | describe)

    # 重要：当前支持两种 debloat manifest 结构：
    # 1. legacy flat list：每项自己声明 `act`
    # 2. grouped record：顶层按 `disable-user` / `uninstall-user0` 分组
    # grouped 写法更适合长期维护，因为 action 不需要在每一项重复书写。
    if ($config_type | str starts-with 'record') {
        let disable_items = ($config.'disable-user'? | default [])
        let uninstall_items = ($config.'uninstall-user0'? | default [])

        let normalized_disable = (normalize-debloat-group $disable_items 'disable-user' $config_abs)
        let normalized_uninstall = (normalize-debloat-group $uninstall_items 'uninstall-user0' $config_abs)

        return ($normalized_disable | append $normalized_uninstall)
    }

    # 兼容 legacy flat list 格式。
    if not (
        ($config_type | str starts-with 'list<')
        or ($config_type | str starts-with 'table<')
    ) {
        error make {
            msg: $'Invalid debloat config: ($config_abs)'
            help: $'Expected top-level grouped record or flat array, got: ($config_type)'
        }
    }

    $config
}

def normalize-user-id [user_id: string]: nothing -> string {
    if ($user_id | str trim) == '' {
        error make {
            msg: 'user-id must not be empty'
        }
    }

    $user_id
}

def adb-base-args []: nothing -> list<string> {
    []
}

def run-adb [args: list<string>]: nothing -> record {
    let result = (^adb ...$args | complete)

    if $result.exit_code != 0 {
        let stderr_text = ($result.stderr | str trim)
        let stdout_text = ($result.stdout | str trim)
        let help_text = if $stderr_text != '' {
            $stderr_text
        } else if $stdout_text != '' {
            # 重要：Android `pm`/`cmd package` 失败时，常常只把 Failure 信息写到 stdout。
            # 如果这里只看 stderr，报错就会丢失关键上下文。
            $stdout_text
        } else {
            'adb command returned non-zero exit code without stdout/stderr'
        }

        error make {
            msg: $'adb command failed: adb ($args | str join " ")'
            help: $help_text
        }
    }

    $result
}

def run-fdroidcl [args: list<string>]: nothing -> record {
    let result = (^fdroidcl ...$args | complete)

    if $result.exit_code != 0 {
        let stderr_text = ($result.stderr | str trim)

        error make {
            msg: $'fdroidcl command failed: fdroidcl ($args | str join " ")'
            help: $stderr_text
        }
    }

    $result
}

# 当前实现只面向单设备；如果没有 device，这里直接失败。
def ensure-adb-device []: nothing -> nothing {
    let result = (run-adb ['get-state'])
    let state = ($result.stdout | str trim)

    if $state != 'device' {
        error make {
            msg: $'adb device state is not ready: ($state)'
        }
    }
}

def get-installed-packages [user_id: string]: nothing -> list<string> {
    run-adb ['shell' 'pm' 'list' 'packages' '--user' $user_id]
    | get stdout
    | lines
    | each {|line| $line | str replace 'package:' '' }
    | where {|line| $line != '' }
    | sort
}

def get-disabled-packages [user_id: string]: nothing -> list<string> {
    run-adb ['shell' 'pm' 'list' 'packages' '-d' '--user' $user_id]
    | get stdout
    | lines
    | each {|line| $line | str replace 'package:' '' }
    | where {|line| $line != '' }
    | sort
}

def print-app-check-table [apps: list<record>, installed_packages: list<string>]: nothing -> nothing {
    $apps
    | each {|app|
        let package_name = ($app.pkg? | default '')

        {
            pkg: $package_name
            name: ($app.name? | default '')
            status: (if ($installed_packages | any {|pkg| $pkg == $package_name }) { 'installed' } else { 'missing' })
            url: ($app.url? | default '')
            des: ($app.des? | default '')
        }
    }
    | sort-by pkg
    | table -e
}

def ensure-package-field [item: record]: nothing -> string {
    let package_name = ($item.pkg? | default '')

    if ($package_name | str trim) == '' {
        error make { msg: $'Missing pkg field in item: ($item | to nuon)' }
    }

    $package_name
}

def ensure-debloat-action [item: record]: nothing -> string {
    let action_name = ($item.act? | default '')

    if ($action_name not-in ['disable-user' 'uninstall-user0']) {
        error make {
            msg: $'Unsupported debloat act: ($action_name)'
        }
    }

    $action_name
}

def get-debloat-package-names [items: list<record>]: nothing -> list<string> {
    $items
    | each {|item| ensure-package-field $item }
    | uniq
    | sort
}

def get-diag-log-signals []: nothing -> list<string> {
    [
        'PackageManager'
        'ActivityManager'
        'ActivityTaskManager'
        'BroadcastQueue'
        'JobScheduler'
        'AlarmManager'
        'Unable to start service'
        'NameNotFoundException'
        'SecurityException'
        'DeadObjectException'
        'No such provider'
        'Unable to resolve Intent'
        'requires unavailable provider'
        'not found'
        'retry'
        'failed to bind'
        'unable to find explicit activity'
    ]
}

def line-has-pattern [line: string, pattern: string]: nothing -> bool {
    if ($pattern | str trim) == '' {
        false
    } else {
        $line | str contains --ignore-case $pattern
    }
}

def find-line-matches [line: string, patterns: list<string>]: nothing -> list<string> {
    $patterns
    | where {|pattern| line-has-pattern $line $pattern }
    | uniq
}

def collect-matching-lines [
    source: string
    raw_text: string
    packages: list<string>
    signals: list<string> = []
]: nothing -> list<record> {
    $raw_text
    | lines
    | each {|line|
        let matched_packages = (find-line-matches $line $packages)
        let matched_signals = (find-line-matches $line $signals)

        {
            source: $source
            pkg: ($matched_packages | str join ',')
            signals: ($matched_signals | str join ',')
            line: ($line | str trim)
        }
    }
    | where {|row|
        let has_package = (($row.pkg | str trim) != '')
        let has_signal = if ($signals | is-empty) {
            true
        } else {
            (($row.signals | str trim) != '')
        }

        $has_package and $has_signal
    }
}

def normalize-logcat-since [since: string] {
    let raw_value = ($since | str trim)

    if $raw_value == '' {
        error make { msg: 'since must not be empty' }
    }

    if (
        ($raw_value =~ '^\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+$')
        or ($raw_value =~ '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+$')
        or ($raw_value =~ '^\d+\.\d+$')
    ) {
        return $raw_value
    }

    let relative_match = ($raw_value | parse --regex '^(?P<value>\d+)(?P<unit>[smhd])$')

    if ($relative_match | is-empty) {
        error make {
            msg: $'Unsupported since format: ($raw_value)'
            help: 'Use values like 30m, 12h, 2d, or an explicit logcat timestamp.'
        }
    }

    let relative = ($relative_match | first)
    let value = ($relative.value | into int)
    let unit = $relative.unit

    let gnu_expr = match $unit {
        's' => $'($value) seconds ago'
        'm' => $'($value) minutes ago'
        'h' => $'($value) hours ago'
        'd' => $'($value) days ago'
    }

    let gnu_result = (^date -d $gnu_expr '+%m-%d %H:%M:%S.000' | complete)
    if $gnu_result.exit_code == 0 {
        return ($gnu_result.stdout | str trim)
    }

    let bsd_flag = match $unit {
        's' => $'-($value)S'
        'm' => $'-($value)M'
        'h' => $'-($value)H'
        'd' => $'-($value)d'
    }

    let bsd_result = (^date -v $bsd_flag '+%m-%d %H:%M:%S.000' | complete)
    if $bsd_result.exit_code == 0 {
        return ($bsd_result.stdout | str trim)
    }

    error make {
        msg: $'Failed to convert since value for logcat: ($raw_value)'
        help: 'Neither GNU date nor BSD date conversion succeeded on this host.'
    }
}

def get-diag-log-filterspec []: nothing -> list<string> {
    [
        'PackageManager:V'
        'ActivityManager:V'
        'ActivityTaskManager:V'
        'BroadcastQueue:V'
        'JobScheduler:V'
        'AlarmManager:V'
        '*:S'
    ]
}

def print-diag-section [title: string, rows: list<record>]: nothing -> nothing {
    print ''
    print $'=== ($title) ==='

    if ($rows | is-empty) {
        print 'No matching lines found.'
    } else {
        $rows | table -e
    }
}

def run-diag-debloat-log-report [
    config_path: string
    user_id: string
    since: string
]: nothing -> nothing {
    let checked_user_id = (normalize-user-id $user_id)
    let packages = (load-debloat-config $config_path)
    let package_names = (get-debloat-package-names $packages)
    let logcat_since = (normalize-logcat-since $since)

    if ($package_names | is-empty) {
        print 'debloat.yml is empty'
        return
    }

    ensure-adb-device

    let log_output = (run-adb (['logcat' '-d' '-b' 'all' '-T' $logcat_since] | append (get-diag-log-filterspec)) | get stdout)
    let log_matches = (collect-matching-lines 'logcat' $log_output $package_names (get-diag-log-signals))

    print $"Scanning logcat since ($since) for debloat package regressions..."
    print $"Config user: ($checked_user_id); scope: device-wide logs; logcat since: ($logcat_since)"
    print $"Filterspec: ((get-diag-log-filterspec) | str join ' ')"
    print-diag-section 'logcat suspicious matches' $log_matches
}

def run-diag-debloat-jobs-report [
    config_path: string
    user_id: string
]: nothing -> nothing {
    let checked_user_id = (normalize-user-id $user_id)
    let packages = (load-debloat-config $config_path)
    let package_names = (get-debloat-package-names $packages)

    if ($package_names | is-empty) {
        print 'debloat.yml is empty'
        return
    }

    ensure-adb-device

    let activity_services = (
        collect-matching-lines
            'activity-services'
            (run-adb ['shell' 'dumpsys' 'activity' 'services'] | get stdout)
            $package_names
    )
    let alarms = (
        collect-matching-lines
            'alarm'
            (run-adb ['shell' 'dumpsys' 'alarm'] | get stdout)
            $package_names
    )
    let jobs = (
        collect-matching-lines
            'jobscheduler'
            (run-adb ['shell' 'dumpsys' 'jobscheduler'] | get stdout)
            $package_names
    )

    print 'Inspecting service/alarm/job scheduler state for debloat packages...'
    print $"Config user: ($checked_user_id); scope: device-wide dumpsys"
    print-diag-section 'activity services' $activity_services
    print-diag-section 'alarm' $alarms
    print-diag-section 'jobscheduler' $jobs
}

def run-diag-debloat-battery-report [
    config_path: string
    user_id: string
]: nothing -> nothing {
    let checked_user_id = (normalize-user-id $user_id)
    let packages = (load-debloat-config $config_path)
    let package_names = (get-debloat-package-names $packages)

    if ($package_names | is-empty) {
        print 'debloat.yml is empty'
        return
    }

    ensure-adb-device

    let batterystats_matches = (
        collect-matching-lines
            'batterystats'
            (run-adb ['shell' 'dumpsys' 'batterystats'] | get stdout)
            $package_names
    )

    print 'Inspecting batterystats for debloat package references...'
    print $"Config user: ($checked_user_id); scope: device-wide stats"
    print-diag-section 'batterystats' $batterystats_matches
}

def apply-disable-user [package_name: string, user_id: string]: nothing -> string {
    run-adb ['shell' 'pm' 'disable-user' '--user' $user_id $package_name] | ignore
    'applied'
}

def apply-uninstall-user0 [package_name: string, user_id: string]: nothing -> string {
    run-adb ['shell' 'pm' 'uninstall' '--user' $user_id $package_name] | ignore
    'applied'
}

def "main apps-check" [
    --config (-c): string
    --user-id (-u): string = '0'
] {
    let checked_user_id = (normalize-user-id $user_id)
    let config = (load-apps-config $config)
    let fdroid_apps = ($config.fdroid | default [])
    let manual_apps = ($config.manual | default [])
    let all_apps = ($fdroid_apps | append $manual_apps)

    ensure-adb-device

    let installed_packages = (get-installed-packages $checked_user_id)
    print-app-check-table $all_apps $installed_packages
}

def "main apps-install" [
    --config (-c): string
    --user-id (-u): string = '0'
] {
    let checked_user_id = (normalize-user-id $user_id)
    let config = (load-apps-config $config)
    let fdroid_apps = ($config.fdroid | default [])
    let manual_apps = ($config.manual | default [])

    ensure-adb-device

    let installed_packages = (get-installed-packages $checked_user_id)

    if (($fdroid_apps | is-empty) and ($manual_apps | is-empty)) {
        print 'apps.yml is empty'
        return
    }

    if not ($fdroid_apps | is-empty) {
        print 'Updating fdroid indexes...'
        run-fdroidcl ['update'] | ignore
    }

    $fdroid_apps | each {|app|
        let package_name = (ensure-package-field $app)

        if ($installed_packages | any {|pkg| $pkg == $package_name }) {
            print $'[skip] ($package_name) already installed'
        } else {
            print $'[install] ($package_name) via fdroidcl'
            run-fdroidcl ['install' $package_name] | ignore
        }
    } | ignore

    $manual_apps | each {|app|
        let package_name = (ensure-package-field $app)

        if ($installed_packages | any {|pkg| $pkg == $package_name }) {
            print $'[ok] manual app already installed: ($package_name)'
        } else {
            let description = ($app.des? | default '')
            print $'[manual] install ($package_name) yourself ($description)'
        }
    } | ignore
}

def "main debloat-check" [
    --config (-c): string
    --user-id (-u): string = '0'
] {
    let checked_user_id = (normalize-user-id $user_id)
    let packages = (load-debloat-config $config)

    ensure-adb-device

    let installed_packages = (get-installed-packages $checked_user_id)
    let disabled_packages = (get-disabled-packages $checked_user_id)

    $packages
    | each {|item|
        let package_name = (ensure-package-field $item)
        let action_name = (ensure-debloat-action $item)

        let status = if $action_name == 'disable-user' {
            if ($disabled_packages | any {|pkg| $pkg == $package_name }) {
                'done'
            } else {
                'pending'
            }
        } else if ($installed_packages | any {|pkg| $pkg == $package_name }) {
            'pending'
        } else {
            'done'
        }

        {
            pkg: $package_name
            act: $action_name
            status: $status
            des: ($item.des? | default '')
        }
    }
    | sort-by act pkg
    | table -e
}

def "main debloat-apply" [
    --config (-c): string
    --user-id (-u): string = '0'
] {
    let checked_user_id = (normalize-user-id $user_id)
    let packages = (load-debloat-config $config)

    ensure-adb-device

    let installed_packages = (get-installed-packages $checked_user_id)
    let disabled_packages = (get-disabled-packages $checked_user_id)

    $packages | each {|item|
        let package_name = (ensure-package-field $item)
        let action_name = (ensure-debloat-action $item)

        if $action_name == 'disable-user' {
            if ($disabled_packages | any {|pkg| $pkg == $package_name }) {
                print $'[skip] ($package_name) already disabled'
            } else {
                print $'[apply] disable-user ($package_name)'
                apply-disable-user $package_name $checked_user_id | ignore
            }
        } else if ($installed_packages | any {|pkg| $pkg == $package_name }) {
            print $'[apply] uninstall-user0 ($package_name)'
            apply-uninstall-user0 $package_name $checked_user_id | ignore
        } else {
            print $'[skip] ($package_name) already not installed for user ($checked_user_id)'
        }
    } | ignore
}

def "main diag-debloat-log" [
    --config (-c): string
    --user-id (-u): string = '0'
    --since (-s): string = '12h'
] {
    run-diag-debloat-log-report $config $user_id $since
}

def "main diag-debloat-jobs" [
    --config (-c): string
    --user-id (-u): string = '0'
] {
    run-diag-debloat-jobs-report $config $user_id
}

def "main diag-debloat-battery" [
    --config (-c): string
    --user-id (-u): string = '0'
] {
    run-diag-debloat-battery-report $config $user_id
}

def "main diag-debloat-full" [
    --config (-c): string
    --user-id (-u): string = '0'
    --since (-s): string = '12h'
] {
    run-diag-debloat-log-report $config $user_id $since
    run-diag-debloat-jobs-report $config $user_id
    run-diag-debloat-battery-report $config $user_id
}

def main [] {
    print 'Usage: droid.nu <apps-check|apps-install|debloat-check|debloat-apply|diag-debloat-log|diag-debloat-jobs|diag-debloat-battery|diag-debloat-full> [flags]'
}
