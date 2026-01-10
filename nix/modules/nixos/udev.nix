{ config, pkgs, ... }:
{
  services.udev = {
    extraRules = ''
      # Rules for Oryx web flashing and live training
      KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
      KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

      # Keymapp Flashing rules for the Voyager
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"

      SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", MODE="0666"
      SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", MODE="0666"
      SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", ATTRS{idProduct}=="1001", MODE="0666"

      # Generic fallback for USB serial
      SUBSYSTEM=="tty", ATTRS{idVendor}=="*", MODE="0666", GROUP="dialout"
    '';

    packages = with pkgs; [
      qmk-udev-rules
    ];
  };

  users = {
    groups = {
      plugdev = { };
      dialout = { };
    };
    users.${config.user.name}.extraGroups = [
      "plugdev"
      "dialout"
    ];
  };
}
