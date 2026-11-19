{
  pkgs,
  ...
}:
let
  # Upstream asset names carry a build timestamp, so a bump means updating both
  # the version and the id below; then run `nix run .#update-hash -- bambu-studio`.
  version = "02.09.01.70";
  build = "20261103183404";

  src = pkgs.fetchurl {
    name = "BambuStudio-${version}.AppImage";
    url = "https://github.com/bambulab/BambuStudio/releases/download/v${version}/BambuStudio_ubu24-v${version}-${build}.AppImage";
    hash = "sha256-Zo2rsb5Tx1gYnta8iZNShd6l4K9GIWVGsbr9aILpr/A=";
  };
in
pkgs.appimageTools.wrapType2 {
  pname = "bambu-studio";
  inherit version src;

  # The AppImage does not bundle the WebKitGTK it links against; the FHS env
  # supplies it (plus the media stack webkit expects at runtime).
  extraPkgs =
    p: with p; [
      webkitgtk_4_1
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      glib-networking
    ];

  meta = {
    description = "PC Software for BambuLab's 3D printers (prebuilt AppImage)";
    homepage = "https://github.com/bambulab/BambuStudio";
    changelog = "https://github.com/bambulab/BambuStudio/releases/tag/v${version}";
    license = with pkgs.lib.licenses; [
      agpl3Plus
      # Bambu Studio downloads and dlopens a proprietary networking library at
      # first launch whose source is not provided; same reasoning as nixpkgs.
      unfree
    ];
    sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
    mainProgram = "bambu-studio";
    platforms = pkgs.lib.platforms.linux;
  };
}
