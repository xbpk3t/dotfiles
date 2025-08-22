# Colmena deployment configuration
# Replaces ansible playbooks and inventory
{
  meta = {
    nixpkgs = import <nixpkgs> {};

    # Global deployment settings
    description = "Multi-host NixOS deployment (migrated from Ansible)";
  };

  # Production server (replaces ansible hk-server-01)
  hk-server-01 = { name, ... }: {
    deployment = {
      targetHost = "47.79.17.202";
      targetPort = 22;
      targetUser = "root";

      # Deployment tags (equivalent to ansible tags)
      tags = [ "production" "web" "hk" "centos_servers" ];

      # SSH configuration
      ssh.user = "root";
    };

    # Import host configuration
    imports = [
      ./hosts/hk-server-01.nix
    ];

    # Host-specific overrides
    networking.hostName = name;
  };

  # Test container (replaces ansible centos7-test)
  centos7-test = { name, ... }: {
    deployment = {
      targetHost = "localhost";
      targetPort = 34225;
      targetUser = "docker";

      # Test environment tags
      tags = [ "staging" "test" "containers" ];

      # SSH configuration for container
      ssh.user = "docker";
    };

    # Import host configuration
    imports = [
      ./hosts/centos7-test.nix
    ];

    # Host-specific overrides
    networking.hostName = name;
  };

  # Additional hosts can be added here following the same pattern
  # Example for future hosts:
  #
  # new-server = { name, nodes, ... }: {
  #   deployment = {
  #     targetHost = "new-server.example.com";
  #     targetPort = 22;
  #     targetUser = "root";
  #     tags = [ "production" "new" ];
  #   };
  #
  #   imports = [
  #     ./hosts/new-server.nix
  #   ];
  #
  #   networking.hostName = name;
  # };
}
