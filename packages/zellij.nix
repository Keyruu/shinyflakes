{ inputs, pkgs }:
let
  craneLib = inputs.crane.mkLib pkgs;
  src = pkgs.fetchFromGitHub {
    owner = "Keyruu";
    repo = "zellij";
    rev = "1be5c7c088125866d72c8acf59fe270da7f797c2";
    hash = "sha256-TdRUZ3MXhWHDQHc5xIURF7/VjBdJzvmvtuovRtc6fvY=";
  };
in
craneLib.buildPackage {
  pname = "zellij";
  version = "0.46.0-fork";
  inherit src;
  cargoExtraArgs = "--locked --no-default-features --features plugins_from_target,web_server_capability,terminal";
  env.OPENSSL_NO_VENDOR = 1;

  nativeBuildInputs = [
    pkgs.pkg-config
    (pkgs.lib.getDev pkgs.curl)
  ];
  buildInputs = [
    pkgs.curl
    pkgs.openssl
  ];

  doCheck = false;
  meta.mainProgram = "zellij";
}
