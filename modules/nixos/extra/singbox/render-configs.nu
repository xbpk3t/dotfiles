#!/usr/bin/env nu

# Render sing-box server config + client subscription using runtime secrets

# helpers
def ensure-dirs [paths: list<path>] {
  for d in $paths { if not ($d | path exists) { mkdir $d } }
}

def load-json [p: path] {
  let data = (open $p)
  let ty = ($data | describe)
  if ($ty | str contains 'record') or ($ty | str contains 'table') {
    $data
  } else {
    $data | from json
  }
}

def server-config [uuid priv shortid port:int] {
  {
    log: { level: "info" timestamp: true }
    inbounds: [
      {
        type: "vless"
        tag: "vless-reality-in"
        listen: "0.0.0.0"
        listen_port: $port
        users: [ { uuid: $uuid flow: "xtls-rprx-vision" } ]
        tls: {
          enabled: true
          server_name: "www.lovelive-anime.jp"
          reality: { enabled: true private_key: $priv short_id: $shortid }
        }
      }
    ]
    outbounds: [ { type: "direct" tag: "direct" } { type: "block" tag: "block" } ]
    route: { final: "direct" }
  }
}

def client-config [domain port:int uuid pub shortid] {
  {
    log: { disabled: true level: "warn" timestamp: true }
    inbounds: [
      {
        type: "socks"
        tag: "socks-in"
        listen: "127.0.0.1"
        listen_port: 1080
        sniff: true
      }
    ]
    outbounds: [
      {
        type: "vless"
        tag: "proxy"
        server: $domain
        server_port: $port
        uuid: $uuid
        flow: "xtls-rprx-vision"
        tls: {
          enabled: true
          server_name: $domain
          reality: { enabled: true public_key: $pub short_id: $shortid }
        }
      }
      { type: "direct" tag: "direct" }
      { type: "block" tag: "block" }
    ]
    route: { final: "proxy" }
  }
}

def write-json [dest: path data] {
  $data | to json --indent 2 | save -f $dest
}

# entrypoint
def main [
  --secret-path: path
  --token-path: path
  --domain: string
  --singbox-port: int
  --sub-path: path
  --nginx-token-conf: path
] {
  let secrets = (load-json $secret_path)
  let token = (open --raw $token_path | str trim)

  ensure-dirs [ /etc/sing-box /etc/subscriptions /etc/nginx ]

  let server_cfg = (server-config $secrets.uuid $secrets.reality_private_key $secrets.short_id $singbox_port)
  let client_cfg = (client-config $domain $singbox_port $secrets.uuid $secrets.reality_public_key $secrets.short_id)

  write-json /etc/sing-box/config.json $server_cfg
  write-json $sub_path $client_cfg

  ^chmod 600 /etc/sing-box/config.json $sub_path
  ^chown root:nginx $sub_path
  ^chmod 640 $sub_path

  "set $sub_token $token;" | save -f $nginx_token_conf
  ^chown root:nginx $nginx_token_conf
  ^chmod 640 $nginx_token_conf
}
