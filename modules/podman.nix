{ ... }:
{
  networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

  virtualisation.quadlet.autoEscape = true;
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };
}
