{ pkgs, ... }:
pkgs.buildGoModule {
  name = "cap-trace";
  src = ./cap-trace;
  vendorHash = null;
  nativeBuildInputs = [ pkgs.makeWrapper ];
  postFixup = ''
    wrapProgram $out/bin/cap-trace \
      --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [ bpftrace podman ])}
  '';
}