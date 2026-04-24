{ pkgs, ... }:
pkgs.buildGoModule {
  name = "cap-trace";
  src = ./cap-trace;
  vendorHash = "sha256-yH4Lw2K2lDjALPPXVktADpyzTXSjdQAuaw3HVk+zMy8=";
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postFixup = ''
    wrapProgram $out/bin/cap-trace \
      --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [ bpftrace podman ])}
  '';
}