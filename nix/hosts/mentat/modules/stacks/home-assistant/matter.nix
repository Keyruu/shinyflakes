{ config, ... }:
let
  stackPath = "/etc/stacks/matter";
  my = config.services.my.matter;
in
{
  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 root root"
  ];

  # services.my.matter = {
  #   # port = 8981;
  #   backup = {
  #     enable = true;
  #     paths = [ stackPath ];
  #   };
  # };

  # networking.firewall.interfaces.eth0.allowedTCPPorts = [
  #   my.port
  # ];

  virtualisation.quadlet.containers.matter = {
    containerConfig = {
      image = "ghcr.io/matter-js/python-matter-server:8.1.2";
      environments = {
        TZ = "Europe/Berlin";
      };
      # podmanArgs = [
      #   "--security-opt apparmor=unconfined"
      # ];
      # appArmor = "unconfined";
      # exposePorts = [
      #   (toString my.port)
      # ];
      volumes = [
        "${stackPath}/data:/data"
      ];
      networks = [
        "host"
      ];
    };
    serviceConfig = {
      Restart = "always";
    };
  };
}
