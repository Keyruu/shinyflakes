{ pkgs, ... }:
let
  # Fetch the rainbow NixOS logo from the brand site
  nixos-logo-rainbow = pkgs.fetchurl {
    url = "https://brand.nixos.org/logos/nixos-logo-rainbow-gradient-white-regular-horizontal-recommended.svg";
    hash = "sha256-vHWMyfoqjW1I0GIPuQcomHBY0OlWyQALrJCZuVQxKAU=";
  };

  pixels-with-nixos-logo = pkgs.stdenv.mkDerivation {
    name = "plymouth-pixels-nixos";

    nativeBuildInputs = [ pkgs.librsvg ];

    unpackPhase = "true";

    installPhase = ''
      mkdir -p $out/share/plymouth/themes/pixels
      cp -r ${pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "pixels" ]; }}/share/plymouth/themes/pixels/* $out/share/plymouth/themes/pixels/

      # Make files writable
      chmod -R +w $out/share/plymouth/themes/pixels

      ${pkgs.librsvg}/bin/rsvg-convert \
        -w 400 \
        -f png \
        --keep-aspect-ratio \
        ${nixos-logo-rainbow} \
        -o $out/share/plymouth/themes/pixels/nixos-logo.png

      cat >> $out/share/plymouth/themes/pixels/pixels.script << 'EOF'
nixos_image = Image("nixos-logo.png");
nixos_sprite = Sprite();

nixos_sprite.SetImage(nixos_image);
nixos_sprite.SetX(Window.GetX() + (Window.GetWidth() / 2 - nixos_image.GetWidth() / 2)); # center the image horizontally
nixos_sprite.SetY(Window.GetHeight() - nixos_image.GetHeight() - 50); # display just above the bottom of the screen
EOF
    '';
  };
in
{
  boot = {
    plymouth = {
      enable = true;
      theme = "pixels";
      themePackages = [ pixels-with-nixos-logo ];
    };

    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];

    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 0;
  };
}
