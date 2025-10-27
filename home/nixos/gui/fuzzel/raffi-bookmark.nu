#!/usr/bin/env nu

use ./raffi-common.nu [
  open-url
  prompt-fuzzel
]

def main [
  --url: string = ''
  --search-url: string = ''
  --prompt: string = 'Search: '
] {
  if $url == '' and $search_url == '' {
    print --stderr "raffi-bookmark: --url or --search-url is required"
    exit 1
  }

  if $search_url != '' {
    let query = prompt-fuzzel $prompt --lines 0 --input "\n"

    if $query == '' {
      if $url != '' {
        open-url $url
      }
      exit 0
    }

    let encoded = ($query | url encode)
    let target = ($search_url | str replace --all '{{query}}' $encoded)
    open-url $target
    exit 0
  }

  open-url $url
}
