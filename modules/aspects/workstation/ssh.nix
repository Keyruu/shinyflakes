{ ... }:
{
  den.aspects.workstation.ssh = {
    nixos =
      { config, lib, ... }:
      {
        services.openssh = {
          enable = true;
          startWhenNeeded = false;
          openFirewall = false;
          ports = [ 2222 ];
          listenAddresses = [ { addr = config.services.mesh.ip; } ];
          settings = {
            AllowUsers = [ "lucas" ];
            PermitRootLogin = "no";
            DisableForwarding = true;
          };
        };

        networking.firewall.interfaces.${config.services.mesh.interface}.allowedTCPPorts =
          config.services.openssh.ports;

        systemd.services.sshd = {
          wantedBy = lib.mkForce [ ];
          requires = [ "wg-quick-${config.services.mesh.interface}.service" ];
          after = [ "wg-quick-${config.services.mesh.interface}.service" ];
        };
      };
  };
}
