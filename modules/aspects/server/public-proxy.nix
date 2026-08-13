{ lib, ... }:
{
  den.aspects.server.public-proxy = {
    nixos =
      { public-proxy, ... }:
      let
        # Each entry carries its producing host's mesh IP (`hostIp`),
        # baked in at the registry. Falls back to 127.0.0.1 for LAN-only
        # hosts without mesh routing — out-of-scope cross-host reach.
        byDomain = lib.groupBy (e: e.domain) public-proxy;
      in
      {
        services.caddy.virtualHosts = lib.mapAttrs (
          _: entries:
          let
            cfg = lib.head entries;
            targetIp = if cfg.hostIp != null then cfg.hostIp else "127.0.0.1";
          in
          {
            extraConfig = ''
              import coraza-waf
              ${lib.optionalString cfg.cloudflareOnly "import cloudflare-only"}
              reverse_proxy http://${targetIp}:${toString cfg.port}
            '';
          }
        ) byDomain;
      };
  };
}
