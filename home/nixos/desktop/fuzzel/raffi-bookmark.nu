#!/usr/bin/env nu

use ./raffi-common.nu [
  open-url
  prompt-fuzzel
]

def main [
  --url: string = ''
  --search-url: string = ''
  --prompt: string = 'Search: '
  --query: string = ''
] {
  if $url == '' and $search_url == '' {
    print --stderr "raffi-bookmark: --url or --search-url is required"
    exit 1
  }

  if $search_url != '' {
    let provided_query = ($query | str trim)

    let resolved_query = if $provided_query != '' {
      $provided_query
    } else {
      let result = prompt-fuzzel $prompt --lines 0 --input "\n"

      if $result == '' {
        if $url != '' {
          open-url $url
        }
        exit 0
      }

      $result
    }

    let encoded = ($resolved_query | url encode)
    let target = ($search_url | str replace --all '{{query}}' $encoded)
    open-url $target
    exit 0
  }

  open-url $url
}
