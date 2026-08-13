# Nginx whitelist aspect — auto-generate `allow <ip>` rules per service.
#
# Consumer of `den.people.<name>.service-access` + `den.people.<name>.devices`.
# Replaces the hand-rolled `lib.pipe config.services.mesh.people [...]` block
# in modules/aspects/options/my.nix (the nginx vhost generation).
#
# For each service with `proxy.whitelist.enable = true` (or its
# replacement `access.people != []`), generates:
#   allow <person>.<device>.ip;
# for every (person, device) pair in the granted set.
#
# Topology is the gate: only `internal` (or `both`) services get
# the IP allowlist. `external` services are public + OIDC, no IP gate.
#
# ponytail: this is the bridge between the new model and the legacy
# `proxy.whitelist.people` field. Once all stacks move to
# `access.people`, the legacy field is removed and the lookup
# in modules/aspects/options/my.nix is deleted.
{ config, lib, ... }:
{
  den.aspects.server.nginx-whitelist = {
    nixos =
      { config, lib, ... }:
      let
        # services.my entries with IP whitelist still enabled.
        whitelistedServices = lib.filterAttrs (_: svc:
          svc.proxy.whitelist.enable or false
        ) config.services.my;

        # Flatten all persons' service-access into tagged list.
        allAccess = lib.concatLists (lib.mapAttrsToList (person: p:
          map (svc: { inherit person; service = svc; }) p.service-access
        ) config.den.people);

        # Per service, IPs to allow. Expand grantedBy person → all
        # their device IPs.
        allowIpsForService = service:
          let
            grantedPersons = lib.unique (map (entry:
              if entry.service == service then entry.person else null
            ) allAccess);
            filtered = lib.filter (p: p != null) grantedPersons;
            ips = lib.concatMap (person:
              lib.mapAttrsToList (_: device: device.ip)
                (config.den.people.${person}.devices or { })
            ) filtered;
          in
          lib.unique ips;
      in
      {
        services.nginx.virtualHosts = lib.mkMerge (lib.mapAttrsToList (service: cfg:
          lib.mkIf (cfg.proxy.enable && cfg.proxy.server == "nginx" && cfg.port != null) {
            ${cfg.domain} = {
              locations."/".extraConfig = lib.mkIf cfg.proxy.whitelist.enable ''
                ${lib.concatMapStringsSep "\n" (ip: "allow ${ip};") (allowIpsForService service)}
                allow 192.168.100.0/24;
                deny all;
              '';
            };
          }
        ) whitelistedServices);
      };
  };
}
