{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.docker-compose
  ];

  virtualisation.containers.containersConf.settings.network.firewall_driver = "iptables";

  virtualisation.podman = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
      dates = "daily";
    };
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };
}
