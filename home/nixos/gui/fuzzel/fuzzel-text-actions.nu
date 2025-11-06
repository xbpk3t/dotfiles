#!/usr/bin/env nu

use ./raffi-common.nu [
  copy-to-clipboard
  prompt-fuzzel
  notify
]

# Default text actions configuration
const default_actions = [
  {
    name: "Translate"
    command: ["trans", "-b", ":en"]
    output: "clipboard"
  }
  {
    name: "Google Search"
    command: [
      "raffi-bookmark"
      "--search-url"
      "https://www.google.com/search?q={{query}}"
      "--query"
      "%s"
    ]
    output: "none"
    replace_placeholder: true
  }
    {
      name: "Nix Search"
      command: [
        "raffi-bookmark"
        "--search-url"
        "https://mynixos.com/search?q={{query}}"
        "--query"
        "%s"
      ]
      output: "none"
      replace_placeholder: true
    }
  {
    name: "Generate Password"
    command: [
      "raffi-pwgen"
      "--skip-type"
      "--website"
      "%s"
    ]
    output: "none"
    replace_placeholder: true
  }
  {
    name: "GitHub Search"
    command: [
      "raffi-bookmark"
      "--search-url"
      "https://github.com/search?q={{query}}"
      "--query"
      "%s"
    ]
    output: "none"
    replace_placeholder: true
  }
]

# Function to get text actions from config file if it exists, otherwise use defaults
def get-text-actions [] {
  let config_path = ($env.HOME | path join ".config" "raffi" "text-actions.nu")

  # Configuration via source is not allowed during parse time
  # For customization, users can modify the default_actions directly in this script
  # or implement a different configuration mechanism
  $default_actions
}

# Function to execute a text action
def execute-action [action, text] {
  let command = $action.command
  let output_type = $action.output | default "clipboard"

  match $output_type {
    "clipboard" => {
      if ($action | get replace_placeholder? | default false) {
        # Replace %s placeholder in command with the actual text
        let processed_command = ($command | each {|part|
          if $part == "%s" { $text } else { $part }
        })
        let result = (run-external ...$processed_command | complete).stdout
        if ($result != "") {
          copy-to-clipboard $result
        }
      } else {
        # Pipe text to command and copy result
        let result = (echo $text | run-external ...$command | complete).stdout
        if ($result != "") {
          copy-to-clipboard $result
        }
      }
    }
    "none" => {
      if ($action | get replace_placeholder? | default false) {
        # Replace %s placeholder in command with the actual text
        let processed_command = ($command | each {|part|
          if $part == "%s" { $text } else { $part }
        })
        run-external ...$processed_command | complete
      } else {
        # Pipe text to command but don't capture output
        echo $text | run-external ...$command | complete
      }
    }
  }
}

def main [] {
  # Get currently selected text from primary clipboard
  let selected_text = (run-external "wl-paste" "--primary" | complete).stdout | str trim

  let debug_mode = ($env.RAFFI_TEXT_ACTIONS_DEBUG? | default '')

  if $debug_mode != '' {
    print --stderr $"[text-actions] selected text: ($selected_text)"
  }

  if ($selected_text == "") {
    notify "Text Actions" "No selected text found"
    exit 1
  }

  # Get available actions
  let actions = get-text-actions

  # Prepare action names for fuzzel
  let action_names = ($actions | each {|action| $action.name })
  let action_input = ($action_names | str join "\n")

  # Limit the preview of selected text to avoid very long entries
  let text_preview = if ($selected_text | str length) > 50 {
    ($selected_text | str substring 0..50) + "..."
  } else {
    $selected_text
  }

  # Show fuzzel menu with action for the selected text
  let selected_action_name = prompt-fuzzel $"Action for: ($text_preview)" --lines 10 --input $action_input

  if $debug_mode != '' {
    print --stderr $"[text-actions] chosen action: ($selected_action_name)"
  }

  if $selected_action_name == '' {
    exit 1
  }

  # Find the selected action
  let selected_action = (
    $actions
    | where name == $selected_action_name
    | get 0?
  )

  if $selected_action == null {
    notify "Text Actions" $"Unknown action selected: ($selected_action_name)"
    if $debug_mode != '' {
      print --stderr "[text-actions] selected action not found"
    }
    exit 1
  }

  # Execute the selected action
  try {
    if $debug_mode != '' {
      print --stderr $"[text-actions] executing: ($selected_action.name)"
    }
    execute-action $selected_action $selected_text
    notify "Text Actions" $"Executed: ($selected_action_name)"
    exit 0
  } catch {
    if $debug_mode != '' {
      print --stderr "[text-actions] execution failed"
    }
    notify "Text Actions" $"Failed to execute action: ($selected_action_name)"
    exit 1
  }
}

main
