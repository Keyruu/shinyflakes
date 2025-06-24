{
  pkgs,
  lib,
  ...
}:
let
  mcp-proxy = pkgs.callPackage ../../../../pkgs/mcp-proxy.nix { };
in
{
  networking.firewall.interfaces.podman3.allowedTCPPorts = [ 30003 ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 30003 ];

  systemd.services.mcp-searxng = {
    description = "mcp-searxng";
    wantedBy = [ "multi-user.target" ];
    environment = {
      SEARXNG_URL = "http://127.0.0.1:4899";
    };
    serviceConfig = {
      ExecStart = "${lib.getExe mcp-proxy} --port 30003 --host 0.0.0.0 --pass-environment -- ${lib.getExe pkgs.podman} run -i --rm -e SEARXNG_URL --network host isokoliuk/mcp-searxng:latest";
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };
}
