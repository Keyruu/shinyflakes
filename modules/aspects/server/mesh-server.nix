{
  den,
  ...
}:
{
  den.aspects.server.mesh-server = {
    nixos =
      { config, ... }:
      {
        sops.secrets.meshServerKey = {
          mode = "0600";
        };

        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = 1;
          "net.ipv6.conf.all.forwarding" = 1;
        };

        networking.firewall = {
          allowedUDPPorts = [ 51234 ];
          # Mesh peers have to reach each other through the hub: the mesh
          # resolver (100.67.0.2) and the LAN live behind mentat. Without this
          # the NixOS forward chain (policy drop) eats every mesh0 -> mesh0
          # packet, which is why DNS dies while the tunnel is up.
          extraForwardRules = ''
            iifname "mesh0" oifname "mesh0" accept comment "mesh peer-to-peer"
          '';
        };
        networking.nat = {
          enable = true;
          internalInterfaces = [ "mesh0" ];
          externalInterface = "eth0";
        };

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
              }) (concatMap (person: attrValues person.devices) (attrValues den.people));
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
  };
}
