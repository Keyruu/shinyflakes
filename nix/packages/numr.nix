{
  pkgs,
}:
pkgs.rustPlatform.buildRustPackage {
  pname = "numr";
  version = "0.1.1";

  src = pkgs.fetchFromGitHub {
    owner = "nasedkinpv";
    repo = "numr";
    tag = "v0.1.1";
    hash = "sha256-XMaAlrnTs2/7RySS4rqYxJ35EZX9+Ulcga/gL/OLbuI=";
  };

  cargoHash = "sha256-0KzYfYC1AFN/M7W4o4/eCCJmqrgxapb0sWDbi2n/NgU=";

  nativeBuildInputs = with pkgs; [
    pkg-config
  ];

  buildInputs = with pkgs; [
    openssl
  ];

  meta = {
    description = "A text calculator for natural language expressions with a vim-style TUI";
    mainProgram = "numr";
    homepage = "https://github.com/nasedkinpv/numr";
    license = pkgs.lib.licenses.mit;
    maintainers = with pkgs.lib.maintainers; [ keyruu ];
    platforms = pkgs.lib.platforms.all;
  };
}
