{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  libGL,
  libx11,
  libxcursor,
  libxrandr,
  libxi,
  libxinerama,
  libxxf86vm,
  libxext,
  libxcb,
}:
let
  targets = {
    x86_64-linux = {
      arch = "amd64";
      hash = "sha256-guxOG2JdKYjt+RqRKlCbrItJBElIx5Fxot6tQb2leys=";
    };
    aarch64-linux = {
      arch = "arm64";
      hash = "sha256-dhO/hgWnl327LBdlsgp+5NohlFBuf7najr//CCaTjc0=";
    };
  };
  target = targets.${stdenv.hostPlatform.system} or (throw "Rune IDE is only available for x86_64-linux and aarch64-linux");
  guiLibraries = [
    libGL
    libx11
    libxcursor
    libxrandr
    libxi
    libxinerama
    libxxf86vm
    libxext
    libxcb
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "rune-ide";
  version = "1.3.1";

  src = fetchurl {
    url = "https://github.com/unstablebuild/rune/releases/download/v${finalAttrs.version}/rune-v${finalAttrs.version}-linux-${target.arch}.tar.gz";
    inherit (target) hash;
  };
  sourceRoot = "rune.app";

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = guiLibraries;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib" "$out/bin"
    cp -r . "$out/lib/rune.app"
    makeWrapper "$out/lib/rune.app/bin/rune" "$out/bin/rune" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath guiLibraries}"
    runHook postInstall
  '';

  meta = {
    description = "Keyboard-driven IDE and terminal multiplexer";
    homepage = "https://rune.build";
    license = lib.licenses.gpl3Plus;
    platforms = builtins.attrNames targets;
    mainProgram = "rune";
  };
})
