{ config, ... }:

{
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
