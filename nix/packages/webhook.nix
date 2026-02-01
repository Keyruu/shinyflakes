{
  pkgs,
}:
pkgs.buildGoModule rec {
  pname = "webhook";
  version = "2.8.3";

  src = pkgs.fetchFromGitHub {
    owner = "adnanh";
    repo = "webhook";
    rev = "8a2d3f85cd3e0b285239ce1d3d8ec0eddaceb89a";
    sha256 = "sha256-ePEj8m0ZxJFWpZoci8Oy6qTZMG4k9DXLISCBB4c38Yg=";
  };

  vendorHash = null;

  subPackages = [ "." ];

  doCheck = false;

  passthru.tests = { inherit (pkgs.nixosTests) webhook; };

  meta = {
    description = "Incoming webhook server that executes shell commands";
    mainProgram = "webhook";
    homepage = "https://github.com/adnanh/webhook";
    license = pkgs.lib.licenses.mit;
    maintainers = with pkgs.lib.maintainers; [ azahi ];
  };
}
