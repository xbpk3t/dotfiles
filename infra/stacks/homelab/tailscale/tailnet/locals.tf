locals {
  # Nix 生成的共享 infra facts；源文件 infra/facts.nix。
  facts = jsondecode(file("${path.module}/../../../../generated/facts.json"))

  tailnet = local.facts.tailscale.tailnet

  # DERP 节点配置
  # 自定义 Region（与 admin console 的 ACL JSON 中 derpMap 一致）
  derp_map = {
    OmitDefaultRegions = false
    Regions = {
      # 901 (la, dev) 已从 DERP map 移除：
      # agt(上海) -> dev(LA) 公网 TCP 10043 的 TLS 握手被 GFW 重置（裸 TCP 能连上），
      # 经 mihomo fake-IP 代理要 ~5.7s，超过 tailscaled 的 DERP 拨号超时（~2s），
      # 导致 agt 永远连不上自己的 home DERP 'la'，peer 经 relay 发往 agt 的流量
      # 全部丢失（Mac -> agt 表现为 tx 有、rx 0），只能靠 agt 主动打出的直连。
      # 移除后 agt 回退到内置 lax/sfo；dev 上的 derper 仍保留，需要时可重新加入。
      "902" = {
        RegionID   = 902
        RegionCode = "hk-2"
        RegionName = "hk-2"
        Nodes = [{
          Name             = "902"
          RegionID         = 902
          HostName         = "47.79.17.202"
          IPv4             = "47.79.17.202"
          DERPPort         = 10043
          STUNPort         = 10078
          InsecureForTests = true
        }]
      }
      # 903 (cn-sh, agt) 已从 DERP map 移除：
      # dev(LA) -> agt 公网 TCP 10043 被 GFW 挡，且 Mac 会优先选 cn-sh
      # 作为 home DERP，导致 Mac<->dev 单向。移除后 Mac 回退到 sfo/lax/la
      # （dev 都能到）。agt 的 derper 仍保留，需要时可以重新加入。
    }
  }

  # ACL 规则
  acl = {
    # Tailscale Services 要求 service host 是 tagged device。
    # 用专用 tag 只给 nixos-vps-dev，避免影响其他设备的 owner；
    # 单用户 tailnet 下 tag owner 直接给 tailnet owner。
    tagOwners = {
      "tag:svc-9router" = ["xbpk3t@github"]
    }

    # 基础连通：全网全通（保持现状）
    # 注意：授予 autogroup:internet 才能用 exit node。
    # 默认不给全线的 exit 权限，仅手机单独开放 → 其他设备行为不变。
    grants = [
      # 全网互通（不含 exit——exit 由下一规则授权）
      { src = ["*"], dst = ["*"], ip = ["*"] },
      # 仅手机可用 exit node 走互联网（翻墙）
      # 手机 Tailscale 角色名统一为 nod-am（手机节点需在 Tailscale 里改名 nod-am）
      # Tailscale ACL 地址格式要求 user@host（裸 hostname 400 invalid address）
      {
        src = ["xbpk3t@nod-am"]
        dst = ["autogroup:internet"]
        ip  = ["*"]
      }
    ]
    # 自动批准 exit node（无需 tag）：
    # - exitNode: 用户（节点 owner）广告 exit node 时自动批准
    # - routes: 自动批准该用户广告的 0.0.0.0/0 路由（exit node 路由）
    # 用用户身份（xbpk3t）而非 tag —— 单用户 tailnet 无 churn 风险，更简单。
    # 注意：autoApprover 只在新广告时生效；已存在的广告需手动在控制台启用或重新 up。
    autoApprovers = {
      # tailnet owner 的 loginName（API 确认）：xbpk3t@github
      # dev 打上 tag 后 owner 变成 tag，不再匹配 xbpk3t@github，所以把 tag 也加进来，
      # 保持 exit node / 0.0.0.0/0 路由的自动批准不回归。
      exitNode = ["xbpk3t@github", "tag:svc-9router"]
      routes = {
        "0.0.0.0/0" = ["xbpk3t@github", "tag:svc-9router"]
        "::/0"      = ["xbpk3t@github", "tag:svc-9router"]
      }
      # svc:9router / svc:nezha 都由 nixos-vps-dev（已带 tag:svc-9router）
      # 代理；同 tag 自动批准两个 Service host。
      services = {
        "svc:9router" = ["tag:svc-9router"]
        "svc:nezha"   = ["tag:svc-9router"]
      }
    }
    tagOwners = {
      "tag:svc-9router" = ["xbpk3t@github"]
    }
    ssh = [{
      action = "check"
      src    = ["autogroup:member"]
      dst    = ["autogroup:self"]
      users  = ["autogroup:nonroot", "root"]
    }]
  }
}
