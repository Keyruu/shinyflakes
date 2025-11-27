{ ... }:
let
  account_id = "e1c020aa1f59e7dd11541054c6e712e3";
in
{
  resource.cloudflare_zone = {
    keyruu-de = {
      account = {
        id = account_id;
      };
      name = "keyruu.de";
      type = "full";
    };

    peeraten-net = {
      account = {
        id = account_id;
      };
      name = "peeraten.net";
      type = "full";
    };

    buymeaspezi-com = {
      account = {
        id = account_id;
      };
      name = "buymeaspezi.com";
      type = "full";
    };
  };

  output = {
    zone_keyruu_de_id = {
      value = "\${cloudflare_zone.keyruu-de.id}";
    };
    zone_peeraten_net_id = {
      value = "\${cloudflare_zone.peeraten-net.id}";
    };
    zone_buymeaspezi_com_id = {
      value = "\${cloudflare_zone.buymeaspezi-com.id}";
    };
  };
}
