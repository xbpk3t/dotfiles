#!/usr/bin/env nu

# Download subscription, extract outbounds, merge with base JSON, validate, and atomically replace.
# Usage: singbox-update --url <subscription>|--url-file <path> --base <base.json> [--config /var/lib/sing-box/config.json] [--outbounds /var/lib/sing-box/outbounds.json]

export def main [
  --url: string = ""
  --url-file: path = ""
  --base: path = ""
  --config: path = "/var/lib/sing-box/config.json"
  --outbounds: path = "/var/lib/sing-box/outbounds.json"
] {
  let resolved_url = resolve-url $url $url_file
  if ($base | str length) == 0 { error make { msg: "Need --base" } }

  let tmp_raw = temp-path $config "raw"
  let tmp_outbounds = temp-path $outbounds "outbounds"
  let tmp_config = temp-path $config "config"

  let cfg_dir = ($config | path dirname)
  let ob_dir = ($outbounds | path dirname)
  mkdir $cfg_dir
  mkdir $ob_dir
  # ensure directories are root-owned and accessible
  try { ^chown 0:0 $cfg_dir } catch {|_| {}}
  try { ^chown 0:0 $ob_dir } catch {|_| {}}
  try { chmod 700 $cfg_dir } catch {|_| {}}
  try { chmod 700 $ob_dir } catch {|_| {}}

  download-json $resolved_url $tmp_raw
  extract-outbounds $tmp_raw $tmp_outbounds
  merge-config $base $tmp_outbounds $tmp_config
  validate-config $tmp_config
  atomic-write $tmp_outbounds $outbounds
  atomic-write $tmp_config $config
  chmod 600 $config
  print ("Sing-box configuration updated -> " + $config)
}

def resolve-url [url: string, url_file: path] {
  if ($url_file | str length) > 0 {
    open --raw $url_file | str trim
  } else if ($url | str length) > 0 {
    $url
  } else {
    error make { msg: "Need --url or --url-file" }
  }
}

def temp-path [target: path, suffix: string] {
  $target | path dirname | path join ($target | path basename | str replace ".json" ("." + $suffix + ".tmp"))
}

def download-json [url: string, dest: path] {
  let status = (try {
    ^curl --http1.1 -f -S -s -L --retry 3 --retry-delay 5 --retry-max-time 60 --connect-timeout 30 --max-time 120 $url -o $dest
    0
  } catch {|err| $err.exit_code? | default 1 })

  if $status != 0 {
    print ("curl failed (status " + ($status | into string) + ")")
    exit $status
  }

  ensure-json $dest "Downloaded configuration is not valid JSON"
}

def extract-outbounds [raw: path, dest: path] {
  let content = (open --raw $raw)
  let parsed = (try { $content | from json } catch {|_| null })
  let parsed = if $parsed == null {
    # some subscriptions return base64-encoded JSON
    let decoded = (try { $content | ^base64 --decode } catch {|_| null })
    if $decoded == null {
      print "Subscription is neither JSON nor base64-encoded JSON"
      exit 1
    }
    let parsed2 = (try { $decoded | from json } catch {|_| null })
    if $parsed2 == null {
      print "Decoded base64 is not valid JSON"
      exit 1
    }
    $parsed2
  } else { $parsed }

  let dtype = ($parsed | describe)
  let outbounds = if ($dtype | str starts-with "list") {
    $parsed
  } else {
    $parsed.outbounds?
  }
  if $outbounds == null {
    print "No outbounds field found in subscription (got type: " + $dtype + ")"
    exit 1
  }

  $outbounds | to json | save --force $dest
  ensure-json $dest "Extracted outbounds is not valid JSON"
}

def merge-config [base: path, outbounds: path, dest: path] {
  let status = (try { ^jq --slurp '.[1] as $o | .[0] | .outbounds = $o' $base $outbounds | save --force $dest; 0 } catch {|err| $err.exit_code? | default 1 })
  if $status != 0 {
    print "Failed to merge base config with outbounds"
    rm -f $dest
    exit $status
  }
}

def validate-config [config: path] {
  ensure-json $config "Merged config is not valid JSON"
  let sb_status = (try { ^sing-box check -c $config; 0 } catch {|err| $err.exit_code? | default 1 })
  if $sb_status != 0 {
    print "sing-box check failed"
    exit $sb_status
  }
}

def ensure-json [file: path, msg: string] {
  let status = (try { ^jq empty $file; 0 } catch {|err| $err.exit_code? | default 1 })
  if $status != 0 {
    print $msg
    rm -f $file
    exit $status
  }
}

def atomic-write [tmp: path, final: path] {
  mv -f $tmp $final
}
