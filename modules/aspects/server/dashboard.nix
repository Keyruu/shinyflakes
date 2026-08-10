{ lib, ... }:
{
  den.aspects.server.dashboard = {
    nixos =
      { dashboard, ... }:
      let
        # dashboard = [{ value = { title, ... }; source = { host = ...; }; }, ...]
        cards = lib.map (e: e.value) dashboard;
      in
      {
        environment.etc."dashboard/cards.json".text = builtins.toJSON cards;
        # Custom HTML page would be generated from `cards` here.
        # Stub: just expose the JSON so the quirk flow is observable.
        services.caddy.virtualHosts."dash.peeraten.net".extraConfig = ''
          root * /etc/dashboard
          file_server
        '';
      };
  };
}
