#!/usr/bin/env nu

# Generate server secrets for sing-box (uuid + REALITY keys + short_id)

# helpers
def short-id [] {
  ^od -An -N4 -tx1 /dev/urandom
    | str replace -a ' ' ''
    | str trim
}

def reality-keypair [] {
  let parsed = (^sing-box generate reality-keypair
    | lines
    | parse "{key}: {value}")

  let priv = ($parsed | where key =~ 'Private' | get 0 | get value)
  let pub  = ($parsed | where key =~ 'Public'  | get 0 | get value)

  if ($priv | is-empty) or ($pub | is-empty) {
    error make { msg: "sing-box reality-keypair output not parsed" }
  }

  { priv: $priv, pub: $pub }
}

def ensure-parent [p: path] {
  let dir = ($p | path dirname)
  if not ($dir | path exists) { mkdir $dir }
}

def write-secret [dest: path] {
  ensure-parent $dest
  if ($dest | path exists) { rm $dest }

  let uuid = (^uuidgen | str trim)
  let kp = (reality-keypair)
  let sid = (short-id)

  let payload = {
    uuid: $uuid
    reality_private_key: $kp.priv
    reality_public_key: $kp.pub
    short_id: $sid
  }

  $payload | to json --indent 2 | save -f $dest

  ^chmod 600 $dest
}

# entrypoint
def main [--secret-path: path] {
  write-secret $secret_path
}
