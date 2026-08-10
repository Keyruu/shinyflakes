{ lib, ... }:
{
  den.aspects.server.gatus = {
    nixos = { monitor, ... }:
    let
      endpoints = lib.map (entry:
        let value = entry.value; in {
          name = value.name or value.url;
          url = value.url;
          interval = value.interval or "30s";
          conditions = value.conditions or [ "[STATUS] == 200" ];
          alerts = value.alerts or [ { type = "gotify"; } ];
        }
      ) monitor;
    in
    {
      services.gatus = {
        enable = true;
        settings.endpoints = endpoints;
      };
    };
  };
}
