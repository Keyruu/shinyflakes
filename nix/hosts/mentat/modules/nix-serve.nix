{ config, lib, ... }:
let
  port = 7384;
  iptablesRule = ip: "iptables -A INPUT -p tcp -s ${ip} --dport ${toString port} -j ACCEPT";
in
{
  networking.firewall = {
    interfaces.eth0.allowedTCPPorts = [ port ];
    extraCommands = # sh
      ''
        iptablesRule "100.67.0.1"
        ${lib.pipe config.services.mesh.people.lucas.devices [
          (lib.mapAttrsToList (_: device: iptablesRule device.ip))
          (lib.concatStringsSep "\n")
        ]}
      '';
  };

  services.nix-serve = {
    enable = true;
    inherit port;
    openFirewall = false;
    bindAddress = "0.0.0.0";
    secretKeyFile = config.sops.secrets.nixServeKey;
  };
}
