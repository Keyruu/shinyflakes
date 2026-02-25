{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.services) mesh;
  mkPeer = endpoint: {
    publicKey = "ctHXSXda0q3R/NjILCPkWzlJzMc9ekKKpNHpe2Avyh8=";
    allowedIPs = [ mesh.subnet ] ++ mesh.client.allowedIPs;
    inherit endpoint;
    persistentKeepalive = 25;
  };
in
{
  options.services.mesh.client = with lib.types; {
    enable = lib.mkEnableOption "enable client";
    keyName = lib.mkOption {
      type = str;
    };
    autostart = lib.mkOption {
      type = bool;
      default = true;
    };
    allowedIPs = lib.mkOption {
      type = listOf str;
      default = [ ];
    };
    ws = lib.mkEnableOption "enable websocket client";
  };

  config = lib.mkIf mesh.client.enable {
    sops.secrets."${mesh.client.keyName}" = { };
    networking.wg-quick.interfaces = {
      "${mesh.interface}" = {
        address = [ "${mesh.ip}/24" ];
        privateKeyFile = config.sops.secrets."${mesh.client.keyName}".path;
        dns = [ "100.67.0.2" ];
        inherit (mesh.client) autostart;

        peers = [
          (mkPeer "mesh.peeraten.net:51234")
        ];
      };
      "${mesh.interface}-ws" = lib.mkIf mesh.client.ws {
        inherit (config.networking.wg-quick.interfaces."${mesh.interface}")
          address
          privateKeyFile
          dns
          ;

        autostart = false;

        preUp = ''
          echo "trigger" > /dev/udp/127.0.0.1/51234 || true
          sleep 2
        '';

        peers = [
          (mkPeer "127.0.0.1:51234")
        ];
      };
    };

    services.wstunnel = lib.mkIf mesh.client.ws {
      enable = true;
      clients.wg-tunnel = {
        connectTo = "wss://service.peeraten.net";
        settings = {
          local-to-remote = [
            "udp://127.0.0.1:51234:127.0.0.1:51234"
          ];
          http-upgrade-path-prefix = "api/v1/websocket";
          tls-sni-override = "service.peeraten.net";
        };
      };
    };
  };
}
