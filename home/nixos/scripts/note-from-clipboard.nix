{pkgs, ...}:
pkgs.writeShellScriptBin "note-from-clipboard" ''
  #!/usr/bin/env bash

  # Check clipboard content type
  clipboard_type=$(${pkgs.wl-clipboard}/bin/wl-paste --list-types | head -n 1)

  if [[ "$clipboard_type" == "text/plain"* ]]; then
    # It's text, let's create a note
    ${pkgs.wl-clipboard}/bin/wl-paste | note
    if [ $? -eq 0 ]; then
      ${pkgs.libnotify}/bin/notify-send -t 3000 "📝 Note Created" "Clipboard content added as a new note."
    else
      ${pkgs.libnotify}/bin/notify-send -t 5000 -u critical "❌ Note Creation Failed" "There was an error creating the note."
    fi
  else
    # It's not text, so we do nothing and notify the user
    ${pkgs.libnotify}/bin/notify-send -t 4000 -u low "📋 Note Skipped" "Clipboard does not contain text."
  fi
''
