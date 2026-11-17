locals {
  tailnet = "xbpk3t.github"

  # DERP 节点配置
  # 3 个自定义 Region，与 admin console 的 ACL JSON 中 derpMap 一致
  derp_map = {
    OmitDefaultRegions = false
    Regions = {
      "901" = {
        RegionID   = 901
        RegionCode = "la"
        RegionName = "la"
        Nodes = [{
          Name     = "901"
          RegionID = 901
          HostName = "derp-nixos-vps-dev.lucc.dev"
          IPv4     = "192.129.183.26"
          DERPPort = 10043
          STUNPort = 10078
        }]
      }
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
      "903" = {
        RegionID   = 903
        RegionCode = "cn-sh"
        RegionName = "shanghai"
        Nodes = [{
          Name     = "903"
          RegionID = 903
          HostName = "nva.lucc.dev"
          # 注意：dev -> agt 的公网 TCP 10043 被 GFW 挡。尝试过把 DERP
          # 改到 agt tailnet IP，但 Tailscale 客户端不接受，已回滚。
          # Mac 访问 dev 上的服务用 ssh -J agt / agt 反代。
          IPv4     = "1.15.64.188"
          DERPPort = 10043
          STUNPort = 10078
        }]
      }
    }
  }

  # ACL 规则
  acl = {
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
      # tag:svc-9router 也保留：nixos-vps-dev 带该 tag，承担 exit node。
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
