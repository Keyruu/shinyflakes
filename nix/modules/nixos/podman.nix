{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.docker-compose
  ];

  virtualisation.podman = {
    enable = true;
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
    };
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };
}
