{ lib, ... }:
{
  den.aspects.server.public-proxy = {
    nixos =
      { public-proxy, ... }:
      let
        # Stash the producing host's IP onto each entry so vhost generation
        # doesn't have to thread source-context through every step.
        withHostIp = entry: entry.value // { hostIp = entry.source.host.addr; };
        byDomain = lib.groupBy (e: e.domain) (map withHostIp public-proxy);
      in
      {
        services.caddy.virtualHosts = lib.mapAttrs (
          _: entries:
          let
            cfg = lib.head entries;
          in
          {
            extraConfig = ''
              import coraza-waf
              ${lib.optionalString cfg.cloudflareOnly "import cloudflare-only"}
              reverse_proxy http://${cfg.hostIp}:${toString cfg.port}
            '';
          }
        ) byDomain;
      };
  };
}
