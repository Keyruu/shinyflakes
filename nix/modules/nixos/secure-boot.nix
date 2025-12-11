{ pkgs, lib, ... }:
{

  environment.systemPackages = with pkgs; [
    # For debugging and troubleshooting Secure Boot.
    sbctl
    tpm2-tss
    tpm2-tools
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

    # TPM2 Unlocking
    initrd.availableKernelModules = [ "tpm_tis" ];
    initrd.systemd.enable = true;
  };
}
