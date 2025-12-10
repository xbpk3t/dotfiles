#!/usr/bin/env nu

use ./raffi-common.nu [prompt-fuzzel]

def parse-minutes [raw] {
  let trimmed = $raw | str trim
  if $trimmed == '' {
    return null
  }

  let value = (try { $trimmed | into int } catch { null })
  if $value == null or $value <= 0 {
    return null
  }

  $value
}

def format-mm-ss [seconds: int] {
  let minutes_part = (($seconds / 60) | into int)
  let seconds_part = ($seconds mod 60)

  let mm = if $minutes_part < 10 {
    $"0($minutes_part)"
  } else {
    $minutes_part | into string
  }

  let ss = if $seconds_part < 10 {
    $"0($seconds_part)"
  } else {
    $seconds_part | into string
  }

  $"($mm):($ss)"
}

def send-notification [
  message: string
  --replace-id (-r): string = ''
  --urgency (-u): string = ''
  --require-close (-c) = false
] {
  if (which notify-send | is-empty) {
    return $replace_id
  }

  mut args = [
    "--print-id"
    "--app-name"
    "Countdown"
    "--category"
    "timer"
  ]

  if $require_close {
    $args = $args | append ["--expire-time" "0" "--hint" "int:transient:0"]
  } else {
    $args = $args | append ["--expire-time" "0"]
  }

  if $urgency != '' {
    $args = $args | append ["--urgency" $urgency]
  }

  if $replace_id != '' {
    $args = $args | append ["--replace-id" $replace_id]
  }

  $args = $args | append $message

  let output = (
    try {
      ^notify-send ...$args
    } catch {
      ''
    }
  ) | str trim

  if $output == '' {
    $replace_id
  } else {
    $output
  }
}

def wait-notification-dismissed [notification_id: string] {
  if $notification_id == '' {
    return
  }

  if (which makoctl | is-empty) {
    return
  }

  loop {
    let current = (
      try { ^makoctl list } catch { '' }
    )

    if (not ($current | str contains $"Notification ($notification_id):")) {
      break
    }

    sleep 250ms
  }
}

def start-alert-loop [notification_id: string] {
  if $notification_id == '' {
    return ''
  }

  if (which paplay | is-empty) {
    return ''
  }

  if (which systemd-run | is-empty) {
    return ''
  }

  if (which systemctl | is-empty) {
    return ''
  }

  let sound_path = "/run/current-system/sw/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
  if (not ($sound_path | path exists)) {
    return ''
  }

  let unit = $"cc-alert-($notification_id)"

  try { ^systemctl --user stop $unit } catch { null }

  let script = $"trap '' INT TERM; while true; do paplay \"($sound_path)\"; done"

  try {
    ^systemd-run
      --user
      $"--unit=$unit"
      "--property=CollectMode=inactive-or-failed"
      "--collect"
      "--quiet"
      "sh"
      "-c"
      $script
  } catch {
    return ''
  }

  $unit
}

def stop-alert-loop [unit: string] {
  if $unit == '' {
    return
  }

  if (which systemctl | is-empty) {
    return
  }

  try { ^systemctl --user stop $unit } catch { null }
}

def main [...raw_input] {
  let preset = if ($raw_input | is-empty) {
    ''
  } else {
    $raw_input | str join ' ' | str trim
  }

  let initial_line = if $preset == '' { "\n" } else { $preset + "\n" }

  let input = prompt-fuzzel "cc (min): " --lines 0 --input $initial_line
  if $input == '' {
    exit 1
  }

  let minutes = parse-minutes $input
  if $minutes == null {
    print --stderr "cc: 输入的分钟数无效"
    exit 1
  }

  let total_seconds = $minutes * 60
  mut remaining = $total_seconds
  mut notification_id = ''

  while $remaining > 0 {
    let label = format-mm-ss $remaining
    let next_id = send-notification $label --replace-id $notification_id
    $notification_id = $next_id

    sleep 1sec
    $remaining = $remaining - 1
  }

  let final_message = "Time is up"
  let final_id = send-notification $final_message --replace-id $notification_id --urgency critical --require-close true

  let alert_unit = start-alert-loop $final_id

  try {
    wait-notification-dismissed $final_id
  } catch {
    null
  }

  stop-alert-loop $alert_unit
}
