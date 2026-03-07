{
  config,
  pkgs,
  lib,
  ...
}:
let
  my = config.services.my.mentat-cockpit;
in
{
  services = {
    my.mentat-cockpit = {
      enable = true;
      port = 9090;
      domain = "prime.keyruu.de";
    };
    cockpit = {
      inherit (my) enable;
      inherit (my) port;
      plugins = with pkgs; [
        cockpit-zfs
        cockpit-podman
      ];
      settings = {
        WebService = {
          Origins = lib.mkForce "https://prime.keyruu.de wss://prime.keyruu.de";
          ProtocolHeader = "X-Forwarded-Proto";
          ForwardedForHeader = "X-Forwarded-For";
          # Allow HTTP connections from nginx reverse proxy
          AllowUnencrypted = true;
        };
      };
    };
    caddy.virtualHostsWithDefaults."prime.keyruu.de".extraConfig = ''
      import cloudflare-only

      basic_auth * {
        lucas {$PASSWORD_HASH}
      }
      reverse_proxy http://127.0.0.1:${toString my.port}
    '';
  };
}
