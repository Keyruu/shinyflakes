{
  pkgs,
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "librepods";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "kavishdevar";
    repo = "librepods";
    rev = "4737cbfc2c1a4e227e42d095c49ab43bd8d7b64a";
    hash = "sha256-5vPCtjUiFSI/Ix5dbGmR3TGQsYIwWAUHMwx8yH6HXac=";
  };

  sourceRoot = "source/linux-rust";

  cargoHash = "sha256-Ebqx+UU2tdygvqvDGjBSxbkmPnkR47/yL3sCVWo54CU=";

  nativeBuildInputs = with pkgs; [
    pkg-config
    makeWrapper
  ];

  buildInputs = with pkgs; [
    dbus
    libpulseaudio
    wayland
    libxkbcommon
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
  ];

  postFixup = ''
    wrapProgram $out/bin/librepods \
      --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [
        pkgs.wayland
        pkgs.libxkbcommon
        pkgs.vulkan-loader
      ]}
  '';

  meta = {
    description = "Open-source implementation for AirPods features on Linux";
    mainProgram = "librepods";
    homepage = "https://github.com/kavishdevar/librepods";
    license = pkgs.lib.licenses.gpl3Plus;
    platforms = pkgs.lib.platforms.linux;
  };
}
