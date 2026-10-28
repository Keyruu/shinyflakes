{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  bash,
  coreutils,
  findutils,
  git,
  zoxide,
  eza,
  bat,
  fzf,
}:
buildGoModule {
  pname = "herdr-sesh";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "fullerzz";
    repo = "herdr-plugin-sesh";
    rev = "531d0de2ccb61888be08f8380d27845beab5c1bd";
    hash = "sha256-CM42y1H+mepXkt1eLqo9Tsmec1Cy0v5huvPmF1bRETc=";
  };
  vendorHash = "sha256-z8ni2u80UH4WfpmeS3x7KBN2IUb8F6sSOjQB5v1mM/E=";
  subPackages = [ "cmd/herdr-sesh" ];
  ldflags = [
    "-s"
    "-w"
    "-X=github.com/fullerzz/herdr-plugin-sesh/internal/app.Version=0.15.0"
  ];

  # The fzf preview rebuilds PATH; its fallback must also work without /usr/bin.
  postPatch = ''
    substituteInPlace internal/picker/fzf.go \
      --replace-fail '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin' \
        '${
          lib.makeBinPath [
            coreutils
            findutils
          ]
        }:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin'
    substituteInPlace internal/preview/preview_test.go \
      --replace-fail /bin/cat ${lib.getExe' coreutils "cat"}
  '';

  nativeBuildInputs = [ makeWrapper ];
  nativeCheckInputs = [ git ];
  preCheck = ''
    export HOME="$TMPDIR"
  '';
  checkPhase = ''
    runHook preCheck
    go test ./...
    runHook postCheck
  '';

  postInstall = ''
    pluginRoot="$out/share/herdr/plugins/fullerzz.sesh"
    install -Dm644 herdr-plugin.toml "$pluginRoot/herdr-plugin.toml"
    ln -s "$out/bin" "$pluginRoot/bin"
    wrapProgram "$out/bin/herdr-sesh" --prefix PATH : ${
      lib.makeBinPath [
        bash
        git
        zoxide
        eza
        bat
        fzf
      ]
    }
  '';

  meta = {
    description = "Herdr workspace picker with project shortcuts and zoxide history";
    homepage = "https://github.com/fullerzz/herdr-plugin-sesh";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "herdr-sesh";
  };
}
