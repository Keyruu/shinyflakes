{
  config,
  lib,
  pkgs,
  ...
}:
let
  port = 7384;
  iptablesRule = ip: "iptables -A INPUT -p tcp -s ${ip} --dport ${toString port} -j ACCEPT";
in
{
  sops.secrets.nixServeKey = { };

  networking = {
    firewall = {
      interfaces.eth0.allowedTCPPorts = [ port ];
      extraCommands = # sh
        ''
          ${iptablesRule "100.67.0.1"}
          ${lib.pipe config.services.mesh.people.lucas.devices [
            (lib.mapAttrsToList (_: device: iptablesRule device.ip))
            (lib.concatStringsSep "\n")
          ]}
        '';
    };
    hosts."127.0.0.1" = [ "cache.keyruu.de" ];
  };

  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    inherit port;
    openFirewall = false;
    bindAddress = "0.0.0.0";
    secretKeyFile = config.sops.secrets.nixServeKey.path;
  };
}
