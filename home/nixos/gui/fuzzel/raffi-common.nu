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

export def type-into-focused [text] {
  if (not (which ydotool | is-empty)) {
    let ok = (try { ^ydotool type --unicode $text; true } catch { false })
    if $ok { return true }
  }

  if (not (which wtype | is-empty)) {
    let ok = (try { ^wtype --unicode $text; true } catch { false })
    if $ok { return true }
  }

  if (not (which xdotool | is-empty)) {
    let ok = (try { ^xdotool type --delay 0 --clearmodifiers $text; true } catch { false })
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
