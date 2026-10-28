{
  lib,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  pkg-config,
  git,
  gh,
}:
rustPlatform.buildRustPackage {
  pname = "herdr-reviewr";
  version = "0.48.0";

  src = fetchFromGitHub {
    owner = "persiyanov";
    repo = "herdr-reviewr";
    rev = "a253b1bfe4b34182af3204b7fcc42ccfed1b87d9";
    hash = "sha256-Y1AJHvXiIoIkjC3eU9rIBvBl99lvsQ2RIusNXONu2tY=";
  };
  cargoHash = "sha256-6+GnGBWRwfFMPXoim3p8Q8zoj3MdtK2smxkg7133xMg=";

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];
  nativeCheckInputs = [ git ];
  # Process-heavy lock tests assert wall-clock deadlines and interfere when run concurrently.
  dontUseCargoParallelTests = true;

  # Upstream tests inspect their own checkout; fetched archives have no Git metadata.
  preCheck = ''
    export HOME="$TMPDIR"
    git init -b main
    printf '/.cargo/\n' >> .git/info/exclude
    git add --all
    git -c user.name=Nix -c user.email=nix@localhost commit -qm 'Test source snapshot'
  '';

  postInstall = ''
    pluginRoot="$out/share/herdr/plugins/persiyanov.reviewr"
    install -Dm644 herdr-plugin.toml "$pluginRoot/herdr-plugin.toml"
    ln -s "$out/bin" "$pluginRoot/bin"
    wrapProgram "$out/bin/herdr-reviewr" --prefix PATH : ${
      lib.makeBinPath [
        git
        gh
      ]
    }
  '';

  meta = {
    description = "Herdr diff review pane with inline feedback for coding agents";
    homepage = "https://github.com/persiyanov/herdr-reviewr";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "herdr-reviewr";
  };
}
