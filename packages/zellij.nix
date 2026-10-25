{ inputs, pkgs }:
let
  craneLib = inputs.crane.mkLib pkgs;
  src = pkgs.fetchFromGitHub {
    owner = "Keyruu";
    repo = "zellij";
    rev = "f27dfa22fe26910fb896df5895dd2ce0989e83c9";
    hash = "sha256-xkXwyclzA3Y+GnMD2H9UvhnIxe9Z7c6BzDhueHBuSa4=";
  };
in
craneLib.buildPackage {
  pname = "zellij";
  version = "0.46.0-fork";
  inherit src;
  cargoExtraArgs = "--locked --no-default-features --features plugins_from_target,web_server_capability,window";
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
