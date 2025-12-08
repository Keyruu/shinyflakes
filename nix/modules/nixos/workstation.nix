{ flake, ... }:

{
  imports = [
    flake.modules.nixos.systemd-boot
    flake.modules.nixos.bluetooth
    flake.modules.nixos.fonts
    flake.modules.nixos.locale
    flake.modules.nixos.networking
    flake.modules.nixos.build-machines
    flake.modules.nixos.sound
    flake.modules.nixos.graphical
    flake.modules.nixos.onepassword
    flake.modules.nixos.wireguard
    flake.modules.nixos.kanata
    flake.modules.nixos.flatpak
    flake.modules.nixos.thunar
    flake.modules.nixos.voyager
    flake.modules.nixos.nice
    flake.modules.nixos.plymouth
    flake.modules.nixos.podman
  ];
}
