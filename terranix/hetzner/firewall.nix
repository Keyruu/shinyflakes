{ lib, ... }:
let
  ipv4Txt = builtins.fetchurl {
    url = "https://www.cloudflare.com/ips-v4";
    sha256 = "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns=";
  };

  ipv6Txt = builtins.fetchurl {
    url = "https://www.cloudflare.com/ips-v6";
    sha256 = "sha256-np054+g7rQDE3sr9U8Y/piAp89ldto3pN9K+KCNMoKk=";
  };

  parseIpList =
    txt:
    lib.pipe txt [
      builtins.readFile
      (lib.splitString "\n")
      (lib.filter (ip: ip != ""))
    ];

  ipv4 = parseIpList ipv4Txt;
  ipv6 = parseIpList ipv6Txt;

  ips = ipv4 ++ ipv6;

  createPortRule = port: {
    direction = "in";
    protocol = "tcp";
    port = toString port;
    source_ips = ips;
  };

  httpsPorts = [
    80
    443
  ];
  httpsRules = map createPortRule httpsPorts;

  sshRule = {
    direction = "in";
    protocol = "tcp";
    port = "22";
    source_ips = [
      "0.0.0.0/0"
      "::/0"
    ];
  };

  icmpRule = {
    direction = "in";
    protocol = "icmp";
    source_ips = [
      "0.0.0.0/0"
      "::/0"
    ];
  };

  allRules = httpsRules ++ [
    sshRule
    icmpRule
  ];
in
{
  resource.hcloud_firewall.cloudflare-https = {
    name = "cloudflare-https";
    rule = allRules;
  };

  output.firewall_cloudflare_https_id = {
    value = "\${hcloud_firewall.cloudflare-https.id}";
  };
}
