{ lib, ref, ... }:
let

  createPortRule = port: {
    direction = "in";
    protocol = "tcp";
    port = toString port;
    source_ips = [
      "0.0.0.0/0"
      "::/0"
    ];
    # source_ips = ips;
  };

  httpsPorts = [
    80
    443
  ];
  httpsRules = map createPortRule httpsPorts;

  otherRules = [
    # ssh
    {
      direction = "in";
      protocol = "tcp";
      port = "22";
      source_ips = [
        "0.0.0.0/0"
        "::/0"
      ];
    }
    # ping
    {
      direction = "in";
      protocol = "icmp";
      source_ips = [
        "0.0.0.0/0"
        "::/0"
      ];
    }
    # wg
    {
      direction = "in";
      protocol = "udp";
      port = "51234";
      source_ips = [
        "0.0.0.0/0"
        "::/0"
      ];
    }
    {
      direction = "in";
      protocol = "tcp";
      port = "51234";
      source_ips = [
        "0.0.0.0/0"
        "::/0"
      ];
    }
    # hytale
    {
      direction = "in";
      protocol = "udp";
      port = "5520";
      source_ips = [
        "0.0.0.0/0"
        "::/0"
      ];
    }
  ];

  allRules = httpsRules ++ otherRules;
in
{
  resource.hcloud_firewall.cloudflare-https = {
    name = "cloudflare-https";
    rule = allRules;
  };

  output.firewall_cloudflare_https_id = {
    value = ref.hcloud_firewall.cloudflare-https.id;
  };
}
