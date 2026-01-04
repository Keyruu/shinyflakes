{ config, pkgs, ... }:
{
  # Udev rules for ZSA keyboards (Voyager, Moonlander, Ergodox EZ, Planck EZ)
  # Allows device access without elevated privileges for flashing and live training
  services.udev = {
    extraRules = ''
      # Rules for Oryx web flashing and live training
      KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
      KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

      # Keymapp Flashing rules for the Voyager
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"
    '';

    packages = with pkgs; [
      qmk-udev-rules
    ];
  };

  users.groups.plugdev = { };
  users.users.${config.user.name}.extraGroups = [ "plugdev" ];
}
