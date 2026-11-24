{
  hostMeta,
  lib,
  userMeta,
  ...
}:
let
  usDns = [
    "1.1.1.1"
    "8.8.8.8"
  ];
  # Lower the kernel OOM killer's preference for services that keep the box
  # reachable/proxying; earlyoom.avoid covers the userspace side.
  oomProtected = -500;
in
{
  imports = [
    ../default.nix
    # Disk/RAM-constrained appliance: do not decrypt the full fleet set.
    ../../../secrets/minimal.nix
  ];

  # RackNerd ships a static IPv4 (no DHCP) and boots the Ubuntu image with
  # net.ifnames=0. NixOS would otherwise rename the virtio NIC to ens3 and
  # lose the address after the first boot.
  networking = {
    useDHCP = lib.mkForce false;
    usePredictableInterfaceNames = false;

    interfaces.eth0.ipv4.addresses = [
      {
        address = hostMeta.publicIpv4;
        prefixLength = 26;
      }
    ];

    defaultGateway = {
      address = "192.236.224.129";
      interface = "eth0";
    };

    # US VPS: do not inherit the China-oriented resolver/NTP list.
    nameservers = lib.mkForce usDns;
    timeServers = lib.mkForce [
      "time.cloudflare.com"
      "pool.ntp.org"
    ];
  };

  services = {
    # US VPS: do not inherit the China-oriented resolver list.
    resolved.settings.Resolve.FallbackDNS = lib.mkForce usDns;

    # Match agt: Tailscale SSH would otherwise compete with OpenSSH for
    # deploy-rs connections over the tailnet.
    tailscale.extraSetFlags = [ "--ssh=false" ];

    # This box is used by someone who logs in as root with a password. The
    # NixOS baseline disables password auth globally; re-enable it for root
    # only, so `luck` remains key-only. The root password is ME_PASS_HASH (the
    # fleet unified password), set by modules/nixos/kernel/user-group.nix.
    openssh.extraConfig = ''
      Match User root
        PasswordAuthentication yes
        PermitRootLogin yes
    '';

    # 1 GiB budget guard: journald/earlyoom defaults assume a larger box.
    journald.settings.Journal.SystemMaxUse = lib.mkForce "200M";
    earlyoom.freeSwapThreshold = 100;
  };

  # The target is SeaBIOS (no /sys/firmware/efi). disko still creates both
  # the 1 MiB bios_grub and 512 MiB ESP partitions, so only GRUB's target
  # changes. `devices` + mkForce also collapses the duplicate contributed by
  # the base's `grub.device` and disko, which would otherwise trip the
  # mirroredBoots assertion when efiSupport = false.
  boot.loader.grub = {
    devices = lib.mkForce [ "/dev/vda" ];
    efiSupport = lib.mkForce false;
    efiInstallAsRemovable = lib.mkForce false;
  };

  # The base disables PasswordAuthentication globally, and NixOS derives
  # security.pam.services.sshd.unixAuth from that global value. The sshd
  # Match User root block only changes sshd; without this the PAM auth stack
  # is just pam_deny, so root password login always fails.
  security.pam.services.sshd.unixAuth = lib.mkForce true;

  modules = {
    # 1 GiB / 20 GiB: drop the general VPS capabilities this role does not
    # need. The base remains the standard role; these are node-local deltas.
    kernel = {
      fhs.enable = lib.mkForce false;
      vm = {
        enable = lib.mkForce false;
        forwardFilter.enable = lib.mkForce false;
      };

      sysctl.hardware = {
        cpuCores = 1;
        memGiB = 1;
        bwMbps = 1000;
        rttMs = 150;
        # Small-memory profile: 18.75MB tcp buffers, 65536 conntrack,
        # 1-day established timeout. dev/agt keep balanced/performance.
        mode = "steady";
      };

      # Keep the services that keep the box reachable/proxying alive when
      # earlyoom fires; the largest remaining process is nix-daemon.
      earlyoom.avoid = [
        "systemd"
        "sshd"
        "sing-box"
        "tailscaled"
        "nezha-agent"
        "dbus-broker"
        "fail2ban-server"
        "systemd-resolve"
        "systemd-journal"
      ];
    };

    # No hardware watchdog on this KVM; the base setting is a no-op that only
    # logs "Failed to open any watchdog device". earlyoom + OOMScoreAdjust are
    # the real safety net here.
    systemd.manager.watchdog.enable = lib.mkForce false;

    infra = {
      singbox-server.enable = true;
      nezha.agent.uuid = "b09f776b-ac65-484d-9522-31237909ac26";
    };
  };

  # 1 GiB budget guards. nix-tools still provides GC/cache/nixos-cli; only
  # the values that assume a larger box are overridden.
  zramSwap.memoryPercent = lib.mkForce 25;
  users.users.${userMeta.username}.linger = lib.mkForce false;

  nix.settings = {
    # nix-tools defaults to a 500 MiB download buffer; that is a guaranteed
    # OOM on a 1 GiB box.
    download-buffer-size = lib.mkForce 67108864;
    max-jobs = lib.mkForce 1;
    cores = lib.mkForce 1;
  };

  # Keep the proxy path alive under memory pressure. earlyoom avoids these
  # processes; OOMScoreAdjust also lowers the kernel OOM killer's preference.
  systemd.services = {
    nix-daemon.serviceConfig = {
      MemoryHigh = "400M";
      MemoryMax = "600M";
      MemorySwapMax = "512M";
    };
    tailscaled.serviceConfig.OOMScoreAdjust = oomProtected;
    nezha-agent.serviceConfig.OOMScoreAdjust = oomProtected;
    sshd.serviceConfig.OOMScoreAdjust = oomProtected;

    # The package unit already sets Restart=on-failure; a slower restart keeps
    # a full-set deploy from tripping the default start limit while ACME is
    # still issuing certificates.
    sing-box.serviceConfig = {
      RestartSec = "10s";
      OOMScoreAdjust = oomProtected;
    };

    # fail2ban is Python and the largest optional service on this box. Cap it
    # so a log burst cannot take down the proxy; systemd restarts it.
    fail2ban.serviceConfig = {
      OOMScoreAdjust = oomProtected;
      MemoryHigh = "100M";
      MemoryMax = "200M";
    };
  };
}
