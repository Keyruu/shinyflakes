{ lib, ... }:
{
  den.aspects.server.public-proxy = {
    # Cross-host reverse-proxy routes for prime — services running on
    # *other* hosts (typically mentat) that opt in via `proxy.public = true`
    # are routed through prime's caddy to the producing host's mesh IP.
    #
    # Same-host caddy services (liwan, koito, anything else on prime)
    # leave `proxy.public = false` and are written by the inline caddy
    # consumer in modules/aspects/options/my/services.nix.
    nixos =
      { config, public-proxy, ... }:
      let
        ownIp = config.services.mesh.ip;

        # Defense-in-depth: even though the emitter only produces entries
        # for services that explicitly opt in via `proxy.public`, skip
        # entries whose producing host is the consumer itself. Catches the
        # edge case where someone sets `proxy.public = true` on a prime-
        # hosted service by mistake (mesh IP routing back to self breaks).
        crossHost = entry: entry.hostIp != null && entry.hostIp != ownIp;

        byDomain = lib.groupBy (e: e.domain) (lib.filter crossHost public-proxy);
      in
      {
        services.caddy.virtualHosts = lib.mapAttrs (
          _: entries:
          let
            cfg = lib.head entries;
            targetIp = cfg.hostIp;
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