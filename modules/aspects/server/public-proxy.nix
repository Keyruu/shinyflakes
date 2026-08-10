{ lib, ... }:
{
  den.aspects.server.public-proxy = {
    nixos =
      { public-proxy, ... }:
      let
        entries = lib.map (e: e.value // { hostIp = e.source.host.addr; }) public-proxy;
        byDomain = lib.groupBy (e: e.domain) entries;
      in
      {
        services.caddy.virtualHosts = lib.mapAttrs (
          _: es:
          let
            cfg = lib.head es;
          in
          {
            extraConfig = ''
              import coraza-waf
              ${lib.optionalString (cfg.cloudflare or false) "import cloudflare-only"}
              reverse_proxy http://${cfg.hostIp}:${toString cfg.port}
            '';
          }
        ) byDomain;
      };
  };
}
