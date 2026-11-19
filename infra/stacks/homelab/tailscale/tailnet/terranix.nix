# terranix 第二个试点：把 tailscale/tailnet 从 HCL 迁到 Nix。
#
# 生成：
#   task tf:terranix-tailscale
# 等价命令（仓库根目录）：
#   nix develop .#infra --command bash -c \
#     'terranix --with-nulls infra/stacks/homelab/tailscale/tailnet/terranix.nix \
#        | jq -S . > infra/stacks/homelab/tailscale/tailnet/generated.tf.json'
#
# 回退：本 commit 删除了同目录的 main.tf / locals.tf / imports.tf /
# versions.tf / provider.tf，`git revert` 即可恢复。
{ lib, ... }:
let
  facts = import ../../../../facts.nix;

  derp_map = {
    OmitDefaultRegions = false;
    Regions = {
      # 902 (hk-2) 是当前保留的自定义 DERP region。
      # 901 (la) / 903 (cn-sh) 已移除，原因见 git 历史与 HCL 版本注释。
      "902" = {
        RegionID = 902;
        RegionCode = "hk-2";
        RegionName = "hk-2";
        Nodes = [
          {
            Name = "902";
            RegionID = 902;
            HostName = "47.79.17.202";
            IPv4 = "47.79.17.202";
            DERPPort = 10043;
            STUNPort = 10078;
            InsecureForTests = true;
          }
        ];
      };
    };
  };

  acl = {
    # Tailscale Services 要求 service host 是 tagged device。
    tagOwners = {
      "tag:svc-9router" = [ "xbpk3t@github" ];
    };

    grants = [
      {
        src = [ "*" ];
        dst = [ "*" ];
        ip = [ "*" ];
      }
      {
        src = [ "xbpk3t@nod-am" ];
        dst = [ "autogroup:internet" ];
        ip = [ "*" ];
      }
    ];

    autoApprovers = {
      exitNode = [
        "xbpk3t@github"
        "tag:svc-9router"
      ];
      routes = {
        "0.0.0.0/0" = [
          "xbpk3t@github"
          "tag:svc-9router"
        ];
        "::/0" = [
          "xbpk3t@github"
          "tag:svc-9router"
        ];
      };
      services = {
        "svc:9router" = [ "tag:svc-9router" ];
        "svc:nezha" = [ "tag:svc-9router" ];
      };
    };

    ssh = [
      {
        action = "check";
        src = [ "autogroup:member" ];
        dst = [ "autogroup:self" ];
        users = [
          "autogroup:nonroot"
          "root"
        ];
      }
    ];
  };
in
{
  terraform = {
    required_version = ">= 1.8.0";

    required_providers.tailscale = {
      source = "tailscale/tailscale";
      version = "~> 0.18";
    };

    backend.s3 = {
      bucket = "luck-dotfiles-opentofu-state";
      key = "homelab/tailscale/tailnet/terraform.tfstate";
      region = "auto";

      endpoints.s3 = "https://96540bd100b82adba941163704660c31.r2.cloudflarestorage.com";

      skip_credentials_validation = true;
      skip_metadata_api_check = true;
      skip_region_validation = true;
      skip_requesting_account_id = true;
      skip_s3_checksum = true;
      use_path_style = true;
      use_lockfile = true;
    };
  };

  provider.tailscale = {
    tailnet = facts.tailscale.tailnet;
  };

  resource = {
    tailscale_acl.main = {
      # ACL 是静态数据，直接在 Nix 侧编码；derpMap 与 ACL 合并后交给 provider。
      acl = builtins.toJSON (acl // { derpMap = derp_map; });
    };

    tailscale_dns_preferences.main = {
      magic_dns = true;
    };

    tailscale_service = {
      ninerouter = {
        name = "svc:9router";
        comment = "9router dashboard (HTTP over tailnet)";
        ports = [ "tcp:80" ];
      };

      nezha = {
        name = "svc:nezha";
        comment = "Nezha dashboard (HTTP over tailnet)";
        ports = [ "tcp:80" ];
      };
    };

    tailscale_tailnet_key.device_join = {
      reusable = true;
      ephemeral = false;
      preauthorized = false;
      expiry = 7776000;
    };

    tailscale_device_tags.nixos_vps_dev = {
      device_id = lib.tf.ref "data.tailscale_device.servers[\"nixos-vps-dev\"].id";
      tags = [ "tag:svc-9router" ];
      depends_on = [ "tailscale_acl.main" ];
    };

    tailscale_device_key.servers = {
      for_each = lib.tf.ref "data.tailscale_device.servers";
      device_id = lib.tf.ref "each.value.id";
      key_expiry_disabled = true;
    };
  };

  data.tailscale_device.servers = {
    for_each = {
      "nixos-vps-dev" = true;
      "nixos-vps-agt" = true;
    };
    hostname = lib.tf.ref "each.key";
  };
}
