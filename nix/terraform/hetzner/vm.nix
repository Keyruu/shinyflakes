{ ref, ... }:
{
  resource.hcloud_server = {
    sleipnir = {
      name = "sleipnir";
      server_type = "cx22";
      image = "ubuntu-24.04";
      location = "nbg1";
      firewall_ids = [ ref.hcloud_firewall.cloudflare-https.id ];
      labels = {
        cloudflare = "";
        pulumi = "";
      };
    };
  };

  output = {
    sleipnir_ipv4 = {
      value = ref.hcloud_server.sleipnir.ipv4_address;
    };
  };
}
