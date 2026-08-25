#!/usr/bin/env nu

# HearingToggle worker. Hammerspoon (HearingToggle.spoon/init.lua) is the single
# source of truth for the noise lifecycle: it starts/stops this worker, detects
# whether noise is running (pgrep), switches sounds, and cleans up. So this script
# only implements the persistent "loop" playback arm, invoked as:
#     nu bgnoise.nu loop <sound>
# Earlier versions carried the whole start/stop/toggle/next/prev/status CLI and
# PID-file bookkeeping here; that duplicated the loader-owned state machine and
# was pruned.

const ROOT = "/System/Library/AssetsV2/com_apple_MobileAsset_ComfortSoundsAssets"

# Asset IDs are machine-specific — extract from:
# /System/Library/AssetsV2/com_apple_MobileAsset_ComfortSoundsAssets/*.asset/Info.plist
const SOUNDS = [  { name: "rain",   id: "84f9ff9b144a40671c1e273848b1ffc7600e4674" },
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

def asset-files [s: string] {
  let name = (normalize-sound $s)
  let found = ($SOUNDS | where name == $name)
  if (($found | length) == 0) {
    error make { msg: $"unknown sound: ($s). use: rain, stream, ocean, white, pink, brown" }
  }
  let rec = $found.0
  let dir = [$ROOT $"($rec.id).asset" "AssetData"] | path join
  glob $"($dir)/*" | sort
}

def loop-noise [s: string] {
  let sound = (normalize-sound $s)
  let volume = ($env.BGNOISE_VOLUME? | default "0.45")
  let files = (asset-files $sound)

  if ($files | length) == 0 {
    error make { msg: $"no audio files found for ($sound). preview the sound in System Settings first." }
  }

  while true {
    for file in $files {
      # On toggle-off / sound switches, Hammerspoon terminates this worker on
      # purpose. That also drags down the in-flight afplay child, which would
      # otherwise surface as a noisy "terminated by SIGTERM" stderr on every
      # normal F7/F8/F9 action. We ignore that expected shutdown path so the
      # console only shows genuine playback failures.
      do --ignore-errors { ^afplay -v $volume $file }
    }
  }
}

def main [cmd: string, sound: string = "rain"] {
  match $cmd {
    "loop" => { loop-noise $sound }
    _ => {
      print "usage: bgnoise.nu loop <sound>"
      print "  HearingToggle.spoon/init.lua drives start/stop/cycling; this script"
      print "  only implements the persistent 'loop' worker."
      exit 2
    }
  }
}
