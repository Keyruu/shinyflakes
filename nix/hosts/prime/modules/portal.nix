{ config, pkgs, ... }:

{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  networking.firewall = {
    enable = true;
    allowedUDPPorts = [ 51234 ];

    extraCommands = ''
      iptables -A FORWARD -i wg0 -j ACCEPT
      iptables -A FORWARD -o wg0 -j ACCEPT
    '';
    extraStopCommands = ''
      iptables -D FORWARD -i wg0 -j ACCEPT || true
      iptables -D FORWARD -o wg0 -j ACCEPT || true
    '';
  };

  sops.secrets.primePortalKey = {
    mode = "0600";
  };

  networking.wg-quick.interfaces = {
    portal0 = {
      address = [ "100.67.0.1/24" ]; # VPN subnet
      listenPort = 51234;
      privateKeyFile = config.sops.secrets.primePortalKey.path;
      peers = [
        # mentat
        {
          publicKey = "nDCk5Y9nEaoV51hLDGCjzlRyglAx/UcH9v1W9F9/imw=";
          allowedIPs = [ "100.67.0.2/32" ];
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
