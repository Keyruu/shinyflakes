{
  config,
  lib,
  ...
}:
let
  cfg = config.services.my;
  inherit (config.services) mesh;
in
{
  config = lib.mkIf (cfg != { }) {
    networking.firewall.extraCommands =
      let
        mkIPs =
          access:
          lib.flatten (
            map (
              entry:
              if lib.hasAttr entry mesh.people then
                lib.mapAttrsToList (_name: device: device.ip) mesh.people.${entry}
              else
                [ ]
            ) access
          );

        inherit (config.services.mesh) interface;

        rules =
          with lib;
          concatMapStrings (
            name:
            let
              svc = cfg.${name};
              ips = mkIPs svc.access;
              ports = if builtins.isList svc.port then svc.port else [ svc.port ];
              protos =
                if svc.proto == "both" then
                  [
                    "tcp"
                    "udp"
                  ]
                else
                  [ svc.proto ];
            in
            optionalString (svc.access != [ ]) (
              concatMapStrings (
                ip:
                concatMapStrings (
                  port:
                  concatMapStrings (proto: ''
                    iptables -A INPUT -i ${interface} -s ${ip} -p ${proto} --dport ${toString port} -j ACCEPT
                  '') protos
                ) ports
              ) ips
            )
          ) (attrNames cfg);
      in
      # sh
      ''
        iptables -N mesh-services 2>/dev/null || iptables -F mesh-services
        ${rules}
        iptables -A mesh-services -j DROP
        iptables -C INPUT -i ${interface} -j mesh-services 2>/dev/null || iptables -A INPUT -i ${interface} -j mesh-services
      '';
  };
}
