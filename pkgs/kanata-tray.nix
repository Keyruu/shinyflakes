{
  lib,
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  libayatana-appindicator,
  gtk3,
  makeWrapper,
  stdenv,
}:

buildGoModule {
  pname = "kanata-tray";
  version = "v0.6.0"; # Update this with the actual version/date

  src = fetchFromGitHub {
    owner = "rszyma";
    repo = "kanata-tray";
    rev = "HEAD"; # Replace with specific commit hash for reproducibility
    hash = "sha256-kdorh0j0CyNeG8950kERDHr9NFj8WvYfL9GiQV3xJXM="; # You'll need to update this
  };

  vendorHash = "sha256-tW8NszrttoohW4jExWxI1sNxRqR8PaDztplIYiDoOP8=";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = lib.optionals stdenv.isLinux [
    libayatana-appindicator
    gtk3
  ];

  env = {
    CGO_ENABLED = "1";
    GO111MODULE = "on";
  };

  ldflags = [
    "-s"
    "-w"
    "-X main.buildVersion=nix"
    "-X main.buildHash=nix-build"
    "-X main.buildDate=unknown"
  ];

  postInstall = lib.optionalString stdenv.isLinux ''
    wrapProgram $out/bin/kanata-tray \
      --set KANATA_TRAY_LOG_DIR /tmp \
      --prefix PATH : $out/bin
  '';

  meta = with lib; {
    description = "Tray Icon for Kanata";
    longDescription = ''
      A simple wrapper for kanata to control it from tray icon.
      Works on Windows, Linux and macOS.

      Features:
      - Tray icon for kanata, with start/stop/pause buttons
      - Easy switching between multiple kanata configurations from tray icon
      - Allow to set custom tray icons for active kanata layers
      - Blink icon on successful kanata config reload
      - Hooks (custom scripts/programs that will run before/after kanata start/stop)
      - Support for running multiple kanata instances with different configurations at the same time
    '';
    homepage = "https://github.com/rszyma/kanata-tray";
    license = licenses.gpl3Only;
    maintainers = [ ]; # Add your name here if you want
    platforms = platforms.linux ++ platforms.darwin;
    mainProgram = "kanata-tray";
  };
}
