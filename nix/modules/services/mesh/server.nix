{ lib, config, ... }:
let
  cfg = config.services.mesh;
in
{
  options.services.mesh.server.enable = lib.mkEnableOption "Enable for mesh server";

  config = lib.mkIf cfg.server.enable {
    sops.secrets.meshServerKey = {
      mode = "0600";
    };

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    networking.firewall.allowedUDPPorts = [ 51234 ];

    networking.wg-quick.interfaces = {
      mesh0 = {
        address = [ "100.67.0.1/24" ]; # VPN subnet
        listenPort = 51234;
        privateKeyFile = config.sops.secrets.meshServerKey.path;
        peers =
          with builtins;
          map (peer: {
            inherit (peer) publicKey;
            allowedIPs = [
              "${peer.ip}/32"
            ]
            ++ peer.allowedIPs;
            persistentKeepalive = 25;
          }) (concatMap (person: attrValues person.devices) (attrValues cfg.people));
      };
    };

    services.wstunnel = {
      enable = true;
      servers = {
        wg-tunnel = {
          listen = {
            enableHTTPS = false;
            host = "127.0.0.1";
            port = 51233;
          };
          settings = {
            restrict-to = [
              {
                host = "127.0.0.1";
                port = 51234;
              }
            ];
          };
        };
      };
    };
    services.caddy.virtualHosts =
      let
        config = {
          extraConfig = "reverse_proxy 127.0.0.1:51233";
        };
      in
      {
        "service.peeraten.net" = config;
        "mesh.peeraten.net" = config;
      };
  };
}
