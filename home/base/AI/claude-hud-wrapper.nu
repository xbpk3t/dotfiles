#!/usr/bin/env nu

def main [] {
  let cols = (try { tput cols | into int } catch { 120 })
  $env.COLUMNS = (if $cols > 4 { $cols - 4 } else { 1 })

  let config_dir = if ($env.CLAUDE_CONFIG_DIR? | is-not-empty) {
    $env.CLAUDE_CONFIG_DIR
  } else {
    $"($env.HOME)/.claude"
  }

  let plugin_dir = (glob $"($config_dir)/plugins/cache/*/claude-hud/*"
    | sort --natural
    | last
  )

  if ($plugin_dir | is-empty) {
    exit 1
  }

  exec bun --env-file /dev/null $"($plugin_dir)/src/index.ts"
}
