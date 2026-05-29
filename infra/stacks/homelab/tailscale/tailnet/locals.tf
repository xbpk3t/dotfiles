locals {
  tailnet = "xbpk3t.github"

  # DERP 节点配置
  # 3 个自定义 Region，与 admin console 的 ACL JSON 中 derpMap 一致
  derp_map = {
    OmitDefaultRegions = false
    Regions = {
      "900" = {
        RegionID   = 900
        RegionCode = "hk"
        RegionName = "hk"
        Nodes = [{
          Name     = "900"
          RegionID = 900
          HostName = "derp-nixos-vps-svc.lucc.dev"
          IPv4     = "103.85.224.63"
          DERPPort = 10043
          STUNPort = 10078
        }]
      }
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
    }
  }

  # ACL 规则
  acl = {
    grants = [{ src = ["*"], dst = ["*"], ip = ["*"] }]
    ssh = [{
      action = "check"
      src    = ["autogroup:member"]
      dst    = ["autogroup:self"]
      users  = ["autogroup:nonroot", "root"]
    }]
  }
}
