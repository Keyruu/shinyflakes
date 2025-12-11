_:
{
  resource.hcloud_server = {
    sleipnir = {
      name = "sleipnir";
      server_type = "cx22";
      image = "ubuntu-24.04";
      datacenter = "nbg1-dc3";
      firewall_ids = [ "\${hcloud_firewall.cloudflare-https.id}" ];
      labels = {
        cloudflare = "";
        pulumi = "";
      };
    };

    pegasus = {
      name = "pegasus";
      server_type = "cax21";
      image = "debian-12";
      datacenter = "nbg1-dc3";
      firewall_ids = [ "\${hcloud_firewall.cloudflare-https.id}" ];
      labels = {
        cloudflare = "";
        pulumi = "";
      };
    };
  };

  output = {
    sleipnir_ipv4 = {
      value = "\${hcloud_server.sleipnir.ipv4_address}";
    };
    pegasus_ipv4 = {
      value = "\${hcloud_server.pegasus.ipv4_address}";
    };
  };
}
