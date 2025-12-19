#!/usr/bin/env nu

# Download sing-box config using parameters (no env deps).
# Usage: singbox-update --url <subscription> [--config /tmp/sing-box/config.json] [--temp /tmp/sing-box/config.json.tmp]

def main [
  --url: string = ""
  --url-file: path = ""
  --config: path = "/tmp/sing-box/config.json"
  --temp: path = ""
] {
  let resolved_url = if ($url_file | str length) > 0 { open --raw $url_file | str trim }
    else if ($url | str length) > 0 { $url }
    else { error make { msg: "Need --url or --url-file" } }

  let tmp = if ($temp | str length) > 0 { $temp } else { $config | path dirname | path join "config.json.tmp" }

  mkdir ($config | path dirname)

  let curl_status = (try {
    ^curl --http1.1 -f -S -s -L --retry 3 --retry-delay 5 --retry-max-time 60 --connect-timeout 30 --max-time 120 $resolved_url -o $tmp
    0
  } catch {|err| $err.exit_code? | default 1 })

  if $curl_status != 0 {
    print ("curl failed (status " + ($curl_status | into string) + ")")
    exit $curl_status
  }

  let jq_status = (try { ^jq empty $tmp; 0 } catch {|err| $err.exit_code? | default 1 })
  if $jq_status != 0 {
    print "Downloaded configuration is not valid JSON"
    rm -f $tmp
    exit $jq_status
  }

  mv -f $tmp $config
  chmod 0o600 $config
  print ("Sing-box configuration updated -> " + $config)
}
