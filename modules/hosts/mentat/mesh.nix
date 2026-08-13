{ ... }:
{
  den.aspects.mentat.nixos =
    { config, ... }:
    {
      # Mentat is the mesh server. Hand-built WG interface (the mesh-server
      # aspect adds peers + sysctl + nat; this sibling supplies the
      # host-specific endpoint + wg private key path).
      sops.secrets.mentatMeshKey = {
        mode = "0600";
      };

      services.mesh.ip = "100.67.0.2";

      networking.wg-quick.interfaces.mesh0 = {
        address = [ "100.67.0.2/24" ];
        privateKeyFile = config.sops.secrets.mentatMeshKey.path;

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
