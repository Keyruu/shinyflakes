{ lib, ... }:
{
  resource.hcloud_server = {
    sleipnir = {
      name = "sleipnir";
      server_type = "cx22";
      image = "ubuntu-24.04";
      location = "nbg1";
      firewall_ids = [
        (lib.tfRef "hcloud_firewall.cloudflare-https.id")
        (lib.tfRef "hcloud_firewall.turn.id")
      ];
      labels = {
        iac = "";
      };
    };
  };

  output = {
    sleipnir_ipv4 = {
      value = lib.tfRef "hcloud_server.sleipnir.ipv4_address";
    };
  };
}
