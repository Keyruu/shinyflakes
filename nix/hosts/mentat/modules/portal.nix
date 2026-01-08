{ config, ... }:
{
  sops.secrets.mentatPortalKey = {
    mode = "0600";
  };

  services.mesh.interface = "portal0";

  networking.wg-quick.interfaces = {
    portal0 = {
      address = [ "100.67.0.2/24" ];
      privateKeyFile = config.sops.secrets.mentatPortalKey.path;

      peers = [
        {
          publicKey = "ctHXSXda0q3R/NjILCPkWzlJzMc9ekKKpNHpe2Avyh8=";
          allowedIPs = [ "100.67.0.0/24" ];
          endpoint = "168.119.225.165:51234";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
