{ den, ... }:
let
  inherit (den.lib.policy) pipe;
in
{
  den.quirks.dashboard = { description = "Service dashboard cards for prime's HTML UI"; };
  den.quirks.monitor = { description = "Service health checks for mentat's gatus"; };
  den.quirks.scrape = { description = "Service metrics endpoints for mentat's prometheus"; };
  den.quirks.public-proxy = { description = "Service reverse-proxy entries for prime's caddy"; };
  den.quirks.oidc-config = { description = "OIDC client config for prime's authelia"; };

  den.policies.collect-service-facts = { host, ... }: [
    (pipe.from "dashboard"    [ (pipe.collect ({ host, ... }: true)) pipe.withProvenance ])
    (pipe.from "monitor"      [ (pipe.collect ({ host, ... }: true)) pipe.withProvenance ])
    (pipe.from "scrape"       [ (pipe.collect ({ host, ... }: true)) pipe.withProvenance ])
    (pipe.from "public-proxy" [ (pipe.collect ({ host, ... }: true)) pipe.withProvenance ])
    (pipe.from "oidc-config"  [ (pipe.collect ({ host, ... }: true)) pipe.withProvenance ])
  ];

  den.schema.host.includes = [ den.policies.collect-service-facts ];
}
