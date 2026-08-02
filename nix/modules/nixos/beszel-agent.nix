{
  config,
  lib,
  ...
}:
{
  services.beszel.agent = {
    enable = true;
    # smartmon.enable drops PrivateDevices/PrivateUsers so the agent can read
    # /dev/sd*, the podman socket (container stats), and `/dev/disk/by-id/*`
    # paths used by EXTRA_FILESYSTEMS on mentat.
    smartmon.enable = true;
    environment = {
      PORT = "45876";
      KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHPF8VerHU8Y0nq8YruGK1QKRkTWisPgWa/YM5IJVc39";
      HUB_URL = if config.networking.hostName == "mentat" then "http://127.0.0.1:7220" else "https://beszel.lab.keyruu.de";
    };
  };

  # Open mesh access so the hub (mentat) can SSH to the agent's stats
  # endpoint on hosts where it isn't reachable via loopback (i.e. prime).
  networking.firewall.interfaces.mesh0.allowedTCPPorts = [ 45876 ];
}
