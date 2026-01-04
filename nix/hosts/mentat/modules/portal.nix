{ config, ... }:
{
  sops.secrets.mentatPortalKey = {
    mode = "0600";
  };

  networking.wg-quick.interfaces = {
    portal0 = {
      address = [ "100.67.0.2/24" ];
      privateKeyFile = config.sops.secrets.mentatPortalKey.path;

      peers = [
        {
          publicKey = "YQ/S53y2q42HCTBPJrwdur4GD4Ixr0OBA7PiBI0SYQA=";
          allowedIPs = [ "100.67.0.0/24" ];
          endpoint = "168.119.225.165:51234";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
