#!/usr/bin/env nu

const ROOT = "/System/Library/AssetsV2/com_apple_MobileAsset_ComfortSoundsAssets"
const STATE_DIR = "/tmp/bgnoise"
const PID_FILE = "/tmp/bgnoise/pid"
const SOUND_FILE = "/tmp/bgnoise/sound"

# Asset IDs are machine-specific — extract from:
# /System/Library/AssetsV2/com_apple_MobileAsset_ComfortSoundsAssets/*.asset/Info.plist
const SOUNDS = [
  { name: "rain",   id: "84f9ff9b144a40671c1e273848b1ffc7600e4674" },
  { name: "stream", id: "28819384cfd85e329b9eb7c9f99fe3c9fa3fa244" },
  { name: "ocean",  id: "b03f75835edaddae9d6f56056b9cf557e9516905" },
  { name: "white",  id: "af97f24c09d60474730c5270c0f627e662ee6f85" },
  { name: "pink",   id: "6f04cf5385dd10f30d8cc4dbe8ecd25b0f102ade" },
  { name: "brown",  id: "9f784c5cc6ab6eaacd3c6411df95889c52b1ad6d" },
]

def normalize-sound [s: string] {
  match ($s | str downcase) {
    "bright" => "white"
    "balanced" => "pink"
    "dark" => "brown"
    "water" => "stream"
    _ => ($s | str downcase)
  }
}

def sound-record [s: string] {
  let name = (normalize-sound $s)
  let found = ($SOUNDS | where name == $name)
  if (($found | length) == 0) {
    error make { msg: $"unknown sound: ($s). use: rain, stream, ocean, white, pink, brown" }
  }
  $found.0
}

def asset-files [s: string] {
  let rec = (sound-record $s)
  let dir = [$ROOT $"($rec.id).asset" "AssetData"] | path join
  glob $"($dir)/*" | sort
}

def ensure-state-dir [] {
  mkdir $STATE_DIR
}

def current-sound [] {
  if ($SOUND_FILE | path exists) {
    let s = (open $SOUND_FILE | str trim)
    if ($s | is-empty) { "rain" } else { normalize-sound $s }
  } else {
    "rain"
  }
}

def save-current-sound [s: string] {
  ensure-state-dir
  (normalize-sound $s) | save -f $SOUND_FILE
}

def read-pid [] {
  if ($PID_FILE | path exists) {
    open $PID_FILE | str trim
  } else {
    ""
  }
}

def process-alive [pid: string] {
  if ($pid | is-empty) { false } else {
    let r = (^/bin/kill -0 $pid | complete)
    $r.exit_code == 0
  }
}

def worker-pattern [sound?: string] {
  let sp = (script-path)
  if ($sp | is-empty) {
    "HearingToggle.spoon/bgnoise.nu loop"
  } else if $sound == null {
    $"($sp) loop"
  } else {
    $"($sp) loop ($sound)"
  }
}

def matching-pids [pattern: string] {
  let r = (^pgrep -f $pattern | complete)
  if $r.exit_code != 0 {
    []
  } else {
    $r.stdout
    | lines
    | each { |line| $line | str trim }
    | where { |line| not ($line | is-empty) }
  }
}

def latest-matching-pid [pattern: string] {
  let r = (^pgrep -n -f $pattern | complete)
  if $r.exit_code != 0 { "" } else { $r.stdout | str trim }
}

def worker-pids [] {
  matching-pids (worker-pattern)
}

def noise-running [] {
  # We intentionally check both the loop worker and the afplay children.
  # The worker can disappear while afplay keeps running, because detached
  # afplay processes get reparented to PID 1 after the launcher exits.
  # If we only trust the saved PID, the toggle path misdetects "noise off" and
  # a second F8 stacks another loop instead of stopping playback.
  let has_worker = ((worker-pids | length) > 0)
  let has_players = ((matching-pids $ROOT | length) > 0)
  $has_worker or $has_players
}

def save-worker-pid [sound: string] {
  mut pid = ""

  for _ in 1..10 {
    let exact = (latest-matching-pid (worker-pattern $sound))
    if not ($exact | is-empty) {
      $pid = $exact
      break
    }

    let generic = (latest-matching-pid (worker-pattern))
    if not ($generic | is-empty) {
      $pid = $generic
      break
    }

    sleep 100ms
  }

  if ($pid | is-empty) {
    rm -f $PID_FILE
  } else {
    ensure-state-dir
    $pid | save -f $PID_FILE
  }
}

def stop-noise-processes [] {
  let pid = (read-pid)
  if (process-alive $pid) {
    ^/bin/kill $pid | ignore
  }

  for worker_pid in (worker-pids) {
    if ($worker_pid != $pid and not ($worker_pid | is-empty)) {
      ^/bin/kill $worker_pid | ignore
    }
  }

  # Killing the loop worker is not sufficient on macOS. We observed afplay
  # children continue playing after the worker exits, because they get detached
  # and reparented to PID 1. That is why we explicitly kill the Comfort Sounds
  # asset players as well; otherwise F8 looks like it "closed" the noise while
  # audio still leaks from stale afplay processes.
  let _ = (^pkill -f $ROOT | complete)

  rm -f $PID_FILE
}

def stop-noise [] {
  stop-noise-processes
}

def script-path [] {
  $env.BGNOISE_SCRIPT_PATH? | default ""
}

def start-noise [s: string = "rain"] {
  # Always clear both the worker and any stale afplay children first. This
  # looks redundant, but it prevents the exact failure mode where repeated
  # F8/F7/F9 presses accumulate overlapping orphaned players.
  stop-noise-processes

  let sound = (normalize-sound $s)
  let files = (asset-files $sound)

  if ($files | length) == 0 {
    error make {
      msg: $"no audio files for '($sound)'. Open System Settings > Accessibility > Audio > Background Sounds, preview this sound once, then retry."
    }
  }

  save-current-sound $sound

  let nu_bin = (which nu | get 0.path)
  let sp = (script-path)
  if ($sp | is-empty) {
    error make { msg: "BGNOISE_SCRIPT_PATH not set" }
  }

  # Avoid launching a login shell here; Hammerspoon already provides the env
  # we need, and a login shell drags in Home Manager session hooks.
  #
  # We also do not rely on `echo $!` here. In this setup, that proved
  # unreliable when invoked through Nushell + `sh -c`: we observed empty pid
  # files even while audio was already playing, which made toggle think
  # nothing was running. Instead, we start the detached worker and then discover
  # its PID with `pgrep`.
  #
  # We also force stdin to /dev/null. Without that explicit redirection, the
  # detached worker proved flaky in practice: the command could appear to start
  # yet no long-lived loop process survived after the parent shell exited.
  let cmd = $"nohup \"($nu_bin)\" \"($sp)\" loop \"($sound)\" </dev/null >/dev/null 2>&1 &"
  let started = (^/bin/sh -c $cmd | complete)
  if $started.exit_code != 0 {
    error make { msg: $"failed to start bgnoise worker: ($started.stderr | str trim)" }
  }

  save-worker-pid $sound
}

def loop-noise [s: string = "rain"] {
  let sound = (normalize-sound $s)
  let volume = ($env.BGNOISE_VOLUME? | default "0.45")
  let files = (asset-files $sound)

  if ($files | length) == 0 {
    error make { msg: $"no audio files found for ($sound). preview the sound in System Settings first." }
  }

  while true {
    for file in $files {
      # During sound switches and toggle-off, Hammerspoon terminates the worker
      # on purpose. That also tears down the in-flight afplay child, which
      # would otherwise surface as a noisy "terminated by SIGTERM" stderr on
      # every normal F7/F8/F9 action. We ignore that expected shutdown path so
      # the console only shows genuine playback failures.
      do --ignore-errors { ^afplay -v $volume $file }
    }
  }
}

def sound-index [s: string] {
  let names = ($SOUNDS | get name)
  let name = (normalize-sound $s)
  let rows = ($names | enumerate | where item == $name)
  if (($rows | length) == 0) { 0 } else { $rows.0.index }
}

def cycle-sound [dir: int] {
  let names = ($SOUNDS | get name)
  let n = ($names | length)
  let cur = (current-sound)
  let idx = (sound-index $cur)
  let raw = ($idx + $dir)

  let next_idx = if $raw < 0 { $n - 1 } else if $raw >= $n { 0 } else { $raw }

  $names | get $next_idx
}

def smart-toggle [] {
  if (noise-running) { stop-noise } else { start-noise (current-sound) }
}

def smart-next [] {
  start-noise (cycle-sound 1)
}

def smart-prev [] {
  start-noise (cycle-sound -1)
}

def show-status [] {
  {
    noise_running: (noise-running)
    noise_sound: (current-sound)
  }
}

def main [
  cmd: string = "toggle"
  sound: string = "rain"
] {
  match $cmd {
    "play"         => { start-noise $sound }
    "stop"         => { stop-noise }
    "toggle"       => {
      if (noise-running) { stop-noise } else { start-noise $sound }
    }
    "next"         => { start-noise (cycle-sound 1) }
    "prev"         => { start-noise (cycle-sound -1) }
    "status"       => { show-status }
    "loop"         => { loop-noise $sound }
    "smart-toggle" => { smart-toggle }
    "smart-next"   => { smart-next }
    "smart-prev"   => { smart-prev }

    _ => {
      print "usage: bgnoise.nu <cmd> [sound]"
      print "  Commands: play, stop, toggle, next, prev, status, loop"
      print "  Compatibility aliases: smart-toggle, smart-next, smart-prev"
      exit 2
    }
  }
}
