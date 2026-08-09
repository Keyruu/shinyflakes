{
  den.aspects.options.cloudflare =
    {
      lib,
      ...
    }:
    let
      parseIpList = txt: lib.filter (ip: ip != "") (lib.splitString "\n" (builtins.readFile txt));

      fetch =
        v:
        builtins.fetchurl {
          url = "https://www.cloudflare.com/ips-v${v}";
          sha256 =
            if v == "4" then
              "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns="
            else
              "sha256-np054+g7rQDE3sr9U8Y/piAp89ldto3pN9K+KCNMoKk=";
        };

      ipv4 = parseIpList (fetch "4");
      ipv6 = parseIpList (fetch "6");
    in
    {
      options.cloudflare.ips = {
        ipv4 = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Cloudflare IPv4 ranges (ips-v4), pinned at eval time.";
        };
        ipv6 = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Cloudflare IPv6 ranges (ips-v6), pinned at eval time.";
        };
        all = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Cloudflare IPv4 + IPv6 ranges.";
        };
      };

      config.cloudflare.ips = {
        inherit ipv4 ipv6;
        all = ipv4 ++ ipv6;
      };
    };
}
