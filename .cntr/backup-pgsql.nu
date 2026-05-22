#!/usr/bin/env nu

# Backup/restore a project's PostgreSQL database to/from R2 via streaming pg_dump.
# Auto-derives container, DB name, user, and R2 path from the project name.
#
# Usage:
#   nu backup-pgsql.nu <project>                       # backup (backward compat)
#   nu backup-pgsql.nu <project> --dry-run
#   nu backup-pgsql.nu backup <project> [--flags]      # backup (explicit)
#   nu backup-pgsql.nu restore <project> [--flags]     # restore
#
# Design notes:
# - Subcommand dispatch is parser-level: nushell routes `nu script.nu backup ...`
#   to `def "main backup"` automatically. `def main` only receives calls where
#   the first arg doesn't match any subcommand — that's how backward compat works.
# - External commands use `^` prefix (`^docker`, `^rclone`) to prevent silent
#   breakage if nushell later adds a builtin with the same name.
# - `complete` captures the entire pipeline's exit_code + stdout + stderr as a
#   record, which is more reliable than `$env.LAST_EXIT_CODE` (only the last
#   command in the pipe, and can be clobbered by subsequent shell operations).
# - `error make` over `print -e` + `exit`: produces a structured error with span
#   info that callers can inspect with `try`/`catch`, rather than just killing
#   the process.

# ── Helpers ───────────────────────────────────────────────────────────

# Find a running postgres container matching the project name.
# Requires the container name to start with the project name followed by "postgres".
def find-pg-container [project: string]: nothing -> string {
  let result = (
    ^docker ps --format '{{.Names}}'
    | lines
    | str trim
    | where {|c| $c =~ $'^($project).*postgres'}
  )
  if ($result | is-empty) {
    error make {
      msg: $'no running postgres container found for project \'($project)\''
      label: {
        text: 'container auto-detection failed'
        span: (metadata $project).span
      }
      help: 'use --container to specify one manually'
    }
  }
  if ($result | length) > 1 {
    print $'warning: multiple containers match, using first: ($result | first)'
    for c in ($result | skip 1) { print $'    also matched: ($c)' }
  }
  $result | first
}

# Read DEFAULT_SK from environment.
def read-db-password []: nothing -> string {
  let val = $env.DEFAULT_SK?
  if ($val | is-empty) {
    error make {
      msg: 'DEFAULT_SK not set in environment'
      label: {
        text: 'missing DEFAULT_SK'
        span: (metadata $val).span
      }
    }
  }
  $val
}

# Aggregate all derived project configuration into a single record.
def get-project-config [
  project: string,
  --container: string,
  --db-name: string,
  --db-user: string,
  --bucket: string,
]: nothing -> record {
  if ($project | str contains '..') or ($project | str contains '/') {
    error make {
      msg: $'invalid project name: "($project)"'
      label: {
        text: 'project name must not contain .. or /'
        span: (metadata $project).span
      }
    }
  }

  let env_file = $'.cntr/($project)/.env'
  {
    project: $project,
    env_file: $env_file,
    container: (if ($container | is-empty) { find-pg-container $project } else { $container }),
    db_name: (if ($db_name | is-empty) { $project } else { $db_name }),
    db_user: (if ($db_user | is-empty) { $project } else { $db_user }),
    bucket: (if ($bucket | is-empty) { $'r2:($project)-bk/' } else { $bucket }),
  }
}

# Unified dry-run output shared by backup and restore.
def print-dry-run [action: string, cfg: record, --extra: record]: nothing -> nothing {
  print '--- dry-run ---'
  print $'  action:      ($action)'
  print $'  project:     ($cfg.project)'
  print $'  container:   ($cfg.container)'
  print $'  db_name:     ($cfg.db_name)'
  print $'  db_user:     ($cfg.db_user)'
  for item in ($extra | transpose key value) {
    let label = ($item.key | str replace '_' ' ' | fill -w 12)
    print $'  ($label): ($item.value)'
  }
}

# ── Backup implementation ─────────────────────────────────────────────

def run-backup [
  project: string,
  --container: string,
  --db-name: string,
  --db-user: string,
  --bucket: string,
  --retention: int = 30,
  --compress: string = 'gzip',
  --verbose,
  --dry-run,
]: nothing -> nothing {
  let cfg = get-project-config $project --container=$container --db-name=$db_name --db-user=$db_user --bucket=$bucket

  let ext = match $compress {
    'zstd' => '.sql.zst'
    'none' => '.sql'
    _ => '.sql.gz'
  }

  let timestamp = (date now | format date '%Y%m%d-%H%M%S')
  let filename = $'($cfg.project)-pgsql-($timestamp)($ext)'

  if $dry_run {
    let env_exists = $cfg.env_file | path exists
    print-dry-run 'backup' $cfg --extra={
      r2_path: $'($cfg.bucket)($filename)'
      retention: $'($retention) days'
      compress: $compress
      env_file: $cfg.env_file
      env_exists: $env_exists
    }
    print ''
    let cmd = match $compress {
      'zstd' => $'docker exec -e PGPASSWORD=*** ($cfg.container) pg_dump -U ($cfg.db_user) ($cfg.db_name) | zstd | rclone rcat ($cfg.bucket)($filename)'
      'none' => $'docker exec -e PGPASSWORD=*** ($cfg.container) pg_dump -U ($cfg.db_user) ($cfg.db_name) | rclone rcat ($cfg.bucket)($filename)'
      _ => $'docker exec -e PGPASSWORD=*** ($cfg.container) pg_dump -U ($cfg.db_user) ($cfg.db_name) | gzip | rclone rcat ($cfg.bucket)($filename)'
    }
    print $'  would run: ($cmd)'
    if $retention > 0 {
      print $"  would run: rclone delete ($cfg.bucket) --min-age ($retention)d --include '*-pgsql-*.sql*'"
    }
    return
  }

  let password = read-db-password

  let start = (date now)
  print -n $'backing up ($cfg.project) → ($cfg.bucket)($filename)... '

  let pg_dump_args = if $verbose { ['--verbose'] } else { [] }

  let result = if $compress == 'zstd' {
    ^docker exec -e $'PGPASSWORD=($password)' $cfg.container pg_dump ...$pg_dump_args -U $cfg.db_user $cfg.db_name
    | ^zstd
    | ^rclone rcat $'($cfg.bucket)($filename)'
    | complete
  } else if $compress == 'none' {
    ^docker exec -e $'PGPASSWORD=($password)' $cfg.container pg_dump ...$pg_dump_args -U $cfg.db_user $cfg.db_name
    | ^rclone rcat $'($cfg.bucket)($filename)'
    | complete
  } else {
    ^docker exec -e $'PGPASSWORD=($password)' $cfg.container pg_dump ...$pg_dump_args -U $cfg.db_user $cfg.db_name
    | ^gzip
    | ^rclone rcat $'($cfg.bucket)($filename)'
    | complete
  }

  if $result.exit_code != 0 {
    print -e 'failed'
    let stderr_msg = $result.stderr | str trim
    if ($stderr_msg | is-not-empty) { print -e $stderr_msg }
    error make {
      msg: 'backup failed'
      label: {
        text: 'pg_dump pipeline failed'
        span: (metadata $cfg.project).span
      }
    }
  }

  if $verbose and ($result.stderr | str trim | is-not-empty) {
    print -e ($result.stderr | str trim)
  }

  let duration = ((date now) - $start) | format duration ms
  let size = try {
    ^rclone size --json $'($cfg.bucket)($filename)' | from json | get bytes | into filesize
  } catch {
    'unknown'
  }

  print ('done (' + ($duration | into string) + ', ' + ($size | into string) + ')')

  if $retention > 0 {
    # --include ensures only backup files are targeted, avoiding both:
    # - slow full-bucket listing (app data like /0/requests/...)
    # - accidental deletion of non-backup objects
    print -n $'cleaning up backups older than ($retention) days... '
    let clean_result = (^rclone delete $cfg.bucket --min-age $'($retention)d' --include '*-pgsql-*.sql*' | complete)
    if $clean_result.exit_code != 0 {
      print -e 'warning: cleanup failed'
    } else {
      print 'done'
    }
  }

  print $'backup complete: ($filename)'
}

# ── Restore implementation ────────────────────────────────────────────

def run-restore [
  project: string,
  --file: string,
  --container: string,
  --db-name: string,
  --db-user: string,
  --bucket: string,
  --list,
  --verbose,
  --dry-run,
]: nothing -> nothing {
  let cfg = get-project-config $project --container=$container --db-name=$db_name --db-user=$db_user --bucket=$bucket

  if $list {
    print $'available backups in ($cfg.bucket):'
    ^rclone lsl $cfg.bucket
    return
  }

  let filename = if ($file | is-empty) {
    let latest = (
      ^rclone lsjson $cfg.bucket
      | from json
      | sort-by ModTime
      | last
    )
    if ($latest | is-empty) {
      error make {
        msg: $'no backups found in ($cfg.bucket)'
        label: {
          text: 'empty bucket'
          span: (metadata $cfg.bucket).span
        }
      }
    }
    print ('using latest backup: ' + $latest.Name + ' (' + ($latest.ModTime | into string) + ')')
    $latest.Name
  } else {
    $file
  }

  if $dry_run {
    let env_exists = $cfg.env_file | path exists
    print-dry-run 'restore' $cfg --extra={
      source: $'($cfg.bucket)($filename)'
      env_file: $cfg.env_file
      env_exists: $env_exists
    }
    print ''
    let cmd = if ($filename | str ends-with '.zst') {
      $'rclone cat ($cfg.bucket)($filename) | zstd -d | docker exec -i ($cfg.container) psql -U ($cfg.db_user) -d ($cfg.db_name)'
    } else if ($filename | str ends-with '.gz') {
      $'rclone cat ($cfg.bucket)($filename) | gunzip | docker exec -i ($cfg.container) psql -U ($cfg.db_user) -d ($cfg.db_name)'
    } else {
      $'rclone cat ($cfg.bucket)($filename) | docker exec -i ($cfg.container) psql -U ($cfg.db_user) -d ($cfg.db_name)'
    }
    print $'  would run: ($cmd)'
    return
  }

  if ($file | is-empty) {
    let answer = (input $'About to restore latest backup to ($cfg.db_name). Continue? [y/N]: ')
    if ($answer | str downcase) not-in ['y' 'yes'] {
      print 'aborted'
      return
    }
  }

  let password = read-db-password

  let start = (date now)
  print -n $'restoring ($filename) to ($cfg.db_name)... '

  let result = if ($filename | str ends-with '.zst') {
    ^rclone cat $'($cfg.bucket)($filename)'
    | ^zstd -d
    | ^docker exec -i -e $'PGPASSWORD=($password)' $cfg.container psql -U $cfg.db_user -d $cfg.db_name
    | complete
  } else if ($filename | str ends-with '.gz') {
    ^rclone cat $'($cfg.bucket)($filename)'
    | ^gunzip
    | ^docker exec -i -e $'PGPASSWORD=($password)' $cfg.container psql -U $cfg.db_user -d $cfg.db_name
    | complete
  } else {
    ^rclone cat $'($cfg.bucket)($filename)'
    | ^docker exec -i -e $'PGPASSWORD=($password)' $cfg.container psql -U $cfg.db_user -d $cfg.db_name
    | complete
  }

  if $result.exit_code != 0 {
    print -e 'failed'
    let stderr_msg = $result.stderr | str trim
    if ($stderr_msg | is-not-empty) { print -e $stderr_msg }
    error make {
      msg: 'restore failed'
      label: {
        text: 'psql restore pipeline failed'
        span: (metadata $cfg.project).span
      }
    }
  }

  if $verbose {
    let stdout_msg = $result.stdout | str trim
    if ($stdout_msg | is-not-empty) { print $stdout_msg }
    let stderr_msg = $result.stderr | str trim
    if ($stderr_msg | is-not-empty) { print -e $stderr_msg }
  }

  let duration = ((date now) - $start) | format duration ms
  print $'done (($duration))'
  print $'restore complete: ($filename) → ($cfg.db_name)'
}

# ── Entry points ──────────────────────────────────────────────────────

# Backward-compat: nu backup-pgsql.nu <project> [--dry-run]
def main [
  project: string,   # Project name (forwarded to backup)
  --dry-run,         # Print what would happen without executing
] {
  run-backup $project --dry-run=$dry_run
}

# Explicit backup: nu backup-pgsql.nu backup <project> [--flags]
def "main backup" [
  project: string,         # Project name (e.g., axonhub)
  --container: string,     # Override the auto-detected PostgreSQL container name
  --db-name: string,       # Override database name (default: same as project)
  --db-user: string,       # Override database user (default: same as project)
  --bucket: string,        # Override R2 bucket path (default: r2:<project>-bk/)
  --retention: int = 30,   # Delete backups older than this many days (0 = never)
  --compress: string = 'gzip',  # Compression: gzip, zstd, none
  --verbose,               # Print pg_dump verbose output and timing
  --dry-run,               # Print what would happen without executing
] {
  run-backup $project --container=$container --db-name=$db_name --db-user=$db_user --bucket=$bucket --retention=$retention --compress=$compress --verbose=$verbose --dry-run=$dry_run
}

# Explicit restore: nu backup-pgsql.nu restore <project> [--flags]
def "main restore" [
  project: string,       # Project name (e.g., axonhub)
  --file: string,        # Specific backup file to restore (omit for latest)
  --container: string,   # Override the auto-detected PostgreSQL container name
  --db-name: string,     # Override database name (default: same as project)
  --db-user: string,     # Override database user (default: same as project)
  --bucket: string,      # Override R2 bucket path (default: r2:<project>-bk/)
  --list,                # List available backups instead of restoring
  --verbose,             # Print psql output and timing
  --dry-run,             # Print what would happen without executing
] {
  run-restore $project --file=$file --container=$container --db-name=$db_name --db-user=$db_user --bucket=$bucket --list=$list --verbose=$verbose --dry-run=$dry_run
}
