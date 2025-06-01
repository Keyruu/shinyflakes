{
  pkgs,
  lib,
  ...
}:
let
  mcp-proxy = pkgs.callPackage ../../../../pkgs/mcp-proxy.nix { };
in
{
  networking.firewall.interfaces.podman3.allowedTCPPorts = [ 30001 ];

  systemd.services.mcp-fetch = {
    description = "mcp-fetch";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe mcp-proxy} --port 30001 --host 0.0.0.0 -- ${lib.getExe pkgs.podman} run -i --rm mcp/fetch";
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };
}
