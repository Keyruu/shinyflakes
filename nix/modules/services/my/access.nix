{
  config,
  lib,
  ...
}:
let
  cfg = config.services.my;
in
{
  options.access = lib.mkOption {
    type = with lib.types; listOf str;
    default = [ ];
    description = "People e.g.: [ 'simon' ]";
  };

  config = {
    networking.firewall.extraCommands =
      let
        mkIPs =
          access:
          lib.flatten (
            map (
              entry:
              if lib.hasAttr entry cfg.people then
                builtins.mapAttrs (_name: device: device.ip) cfg.people.${entry}
              else
                [ ]
            ) access
          );
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
            optionalString svc.access != [ ] (
              concatMapStrings (
                ip:
                concatMapStrings (
                  port:
                  concatMapStrings (proto: ''
                    iptables -A INPUT -i ${cfg.interface} -s ${ip} -p ${proto} --dport ${toString port} -j ACCEPT
                  '') protos
                ) ports
              ) ips
            )
          ) (attrNames cfg);
        inherit (config.services.mesh) interface;
      in
      # sh
      ''
        iptables -N mesh-services 2>/dev/null || iptables -F mesh-services
        ${rules}
        iptables -A mesh-services -j DROP
        iptables -C INPUT -i ${interface} -j mesh-services 2>/dev/null || \
          iptables -A INPUT -i ${interface} -j mesh-services
      '';
  };
}
