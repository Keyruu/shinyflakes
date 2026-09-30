{ inputs, lib, ... }:
{
  den.aspects.workstation.secure-boot = {
    nixos = { pkgs, ... }: {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      environment.systemPackages = with pkgs; [
        sbctl
      ];

      # Lanzaboote currently replaces the systemd-boot module.
      # This setting is usually set to true in configuration.nix
      # generated at installation time. So we force it to false
      # for now.
      boot = {
        loader.systemd-boot.enable = lib.mkForce false;

        lanzaboote = {
          enable = true;
          pkiBundle = "/var/lib/sbctl";
        };
      };
    };
  };
}
