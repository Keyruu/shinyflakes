{ pkgs, config, ... }:
{
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
        3010
        3020
      ];
    };

    nameservers = [
      "192.168.100.1"
      "1.1.1.1"
    ];
    defaultGateway = {
      address = "192.168.100.1";
      interface = "eth0";
    };

    interfaces.eth0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.100.7";
          prefixLength = 24;
        }
      ];
    };
  };

  services.tailscale = {
    enable = false;
    useRoutingFeatures = "both";
    authKeyFile = config.sops.secrets.headscaleAuthKey.path;
    extraUpFlags = [
      "--login-server=https://headscale.peeraten.net"
      "--advertise-exit-node"
      "--advertise-routes=192.168.100.0/24"
      "--accept-dns=true"
      "--accept-routes=false"
    ];
  };

  services.networkd-dispatcher = {
    enable = true;
    rules."50-tailscale" = {
      onState = [ "routable" ];
      script = ''
        ${pkgs.ethtool}/bin/ethtool -K eth0 rx-udp-gro-forwarding on rx-gro-list off
      '';
    };
  };
}
