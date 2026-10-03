{ config, lib, ... }:
{
  den.aspects.services.turn = {
    nixos = { config, ... }:
    let
      my = config.services.my.turn;
    in
    {
      sops.secrets.turnSecret = { };

      sops.templates."turnserver.conf" = {
        restartUnits = [ "turn.service" ];
        content = ''
          listening-port=3478
          tls-listening-port=5349
          realm=turn.peeraten.net
          use-auth-secret
          static-auth-secret=${config.sops.placeholder.turnSecret}
          min-port=49160
          max-port=49200
          no-multicast-peers
          no-cli
          no-tlsv1
          no-tlsv1_1
          cipher-list="ECDHE+AESGCM:ECDHE+CHACHA20:DHE+AESGCM:DHE+CHACHA20"
          fingerprint
          log-file=/var/log/turn/turn.log
          simple-log
        '';
      };

      networking.firewall.allowedUDPPorts = [ 3478 ];
      networking.firewall.allowedTCPPorts = [ 3478 5349 ];
      networking.firewall.allowedUDPPortRanges = [
        { from = 49160; to = 49200; }
      ];

      services.my.turn = {
        title = "TURN";
        description = "TURN/STUN server for Matrix voice/video calls";
        domain = "turn.peeraten.net";
        port = 3478;
        proxy.enable = false;
        stack = {
          enable = true;
          user.enable = true;
          network.enable = true;
          security.enable = true;
          directories = [ "log" ];
          containers.turn = {
            containerConfig = {
              image = "docker.io/coturn/coturn:4.7";
              exec = "--no-daemon --config /etc/turnserver.conf";
              publishPorts = [
                "3478:3478/udp"
                "3478:3478/tcp"
                "5349:5349/tcp"
                "49160-49200:49160-49200/udp"
              ];
              volumes = [
                "${config.sops.templates."turnserver.conf".path}:/etc/turnserver.conf:ro"
                "${my.stack.path}/log:/var/log/turn"
              ];
              networkAliases = [ "turn" ];
              addCapabilities = [ "NET_ADMIN" "NET_BIND_SERVICE" "CHOWN" "DAC_OVERRIDE" "FOWNER" "SETUID" "SETGID" "SYS_RESOURCE" ];
            };
            security.noNewPrivileges = false;
          };
        };
      };
    };
  };
}
