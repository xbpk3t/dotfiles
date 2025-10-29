export def copy-to-clipboard [text] {
  if (not (which wl-copy | is-empty)) {
    let ok = (try { echo $text | ^wl-copy; true } catch { false })
    if $ok { return true }
  }

  if (not (which xclip | is-empty)) {
    let ok = (try { echo $text | ^xclip -selection clipboard; true } catch { false })
    if $ok { return true }
  }

  false
}

def wtype-paste-from-clipboard [text] {
  if (not (copy-to-clipboard $text)) {
    return false
  }

  sleep 50ms

  let combos = [
    { hold: 'ctrl', key: 'v' }
    { hold: 'shift', key: 'Insert' }
  ]

  for combo in $combos {
    let args = [
      '-M' $combo.hold
      '-k' $combo.key
      '-m' $combo.hold
    ]

    let ok = (try { ^wtype ...$args; true } catch { false })
    if $ok { return true }
  }

  false
}

export def type-into-focused [text] {
  let text_to_type = ($text | default '' | into string)

  if $text_to_type == '' {
    return true
  }

  if (not (which wtype | is-empty)) {
    if (wtype-paste-from-clipboard $text_to_type) {
      return true
    }

    # Fallback to direct typing if clipboard paste is not available.
    let ok = (try { $text_to_type | ^wtype -; true } catch { false })
    if $ok { return true }
  }

  if (not (which ydotool | is-empty)) {
    let ok = (try { ^ydotool type --unicode $text_to_type; true } catch { false })
    if $ok { return true }
  }

  if (not (which xdotool | is-empty)) {
    let ok = (try { ^xdotool type --delay 0 --clearmodifiers $text_to_type; true } catch { false })
    if $ok { return true }
  }

  false
}

export def notify [title body] {
  if (which notify-send | is-empty) {
    return
  }

  try {
    ^notify-send $title $body
  } catch {
    null
  }
}

export def open-url [url --message: string = ''] {
  try {
    ^xdg-open $url
  } catch {
    print --stderr $"Failed to open URL: ($url)"
    return
  }

  if $message != '' {
    notify "GitHub" $message
  }
}

export def prompt-fuzzel [
  prompt
  --lines: int = 20
  --input: string = ''
] {
  let clean_input = if $input == '' {
    ''
  } else if ($input | str ends-with "\n") {
    $input
  } else {
    $input + "\n"
  }

  let result = (
    try {
      if $clean_input == '' {
        ^fuzzel --dmenu --prompt $prompt --lines $lines
      } else {
        $clean_input | ^fuzzel --dmenu --prompt $prompt --lines $lines
      }
    } catch {
      ''
    }
  ) | str trim

  $result
}
