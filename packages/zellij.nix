{ inputs, pkgs }:
let
  craneLib = inputs.crane.mkLib pkgs;
  src = inputs.zellij;
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
