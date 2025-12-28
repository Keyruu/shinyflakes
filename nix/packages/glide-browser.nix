# source: https://github.com/caliguIa/nix-config/blob/main/modules/nixos/desktop/glide.nix
{
  pkgs,
  ...
}:
pkgs.stdenv.mkDerivation rec {
  pname = "glide-browser";
  version = "0.1.55a";
  src = pkgs.fetchurl {
    url = "https://github.com/glide-browser/glide/releases/download/${version}/glide.linux-x86_64.tar.xz";
    sha256 = "sha256-mjk8KmB/T5ZpB9AMQw1mtb9VbMXVX2VV4N+hWpWkSYI=";
  };
  nativeBuildInputs = with pkgs; [
    wrapGAppsHook3
    autoPatchelfHook
    patchelfUnstable
  ];
  buildInputs = with pkgs; [
    gtk3
    adwaita-icon-theme
    gdk-pixbuf
    cairo
    pango
    atk
    glib
    libcanberra-gtk3
    xorg.libX11
    xorg.libxcb
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXtst
    xorg.libxshmfence
    xorg.libXxf86dga
    xorg.libXxf86vm
    xorg.libXt
    libdrm
    libGL
    mesa
    libglvnd
    vulkan-loader
    alsa-lib
    pipewire
    ffmpeg
    libfido2
    libu2f-host
    libusb-compat-0_1
    opensc
    pam_u2f
    yubico-pam
    pcsc-tools
    dbus-glib
    cups
    stdenv.cc
    zlib
    speechd-minimal
    libkrb5
    desktop-file-utils
  ];
  runtimeDependencies =
    with pkgs;
    [
      curl
      pciutils
      libva.out
      libnotify
      udev
      libgbm
    ]
    ++ buildInputs;
  appendRunpaths = with pkgs; [
    "${pipewire}/lib"
    "${libglvnd}/lib"
    "${mesa}/lib"
  ];
  patchelfFlags = [ "--no-clobber-old-sections" ];
  sourceRoot = ".";
  installPhase = ''
    mkdir -p $out/lib/glide-browser-${version}
    cp -r glide/* $out/lib/glide-browser-${version}/
    mkdir -p $out/bin
    ln -s $out/lib/glide-browser-${version}/glide $out/bin/glide
    ln -s $out/bin/glide $out/bin/glide-browser
  '';
  preFixup = ''
    gappsWrapperArgs+=(
      --set MOZ_LEGACY_PROFILES 1
      --set MOZ_ALLOW_DOWNGRADE 1
      --set-default MOZ_ENABLE_WAYLAND 1
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath runtimeDependencies}"
    )
  '';
  meta = {
    description = "Glide Browser";
    homepage = "https://github.com/glide-browser/glide";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "glide";
  };
}
