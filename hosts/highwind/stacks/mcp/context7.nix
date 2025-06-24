{
  pkgs,
  lib,
  ...
}:
let
  mcp-proxy = pkgs.callPackage ../../../../pkgs/mcp-proxy.nix { };
in
{
  networking.firewall.interfaces.podman3.allowedTCPPorts = [ 30004 ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 30004 ];

  systemd.services.context7 = {
    description = "context7";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe mcp-proxy} --port 30004 --host 0.0.0.0 -- ${lib.getExe pkgs.podman} run -i --rm context7-mcp";
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };
}
