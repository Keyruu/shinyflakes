{
  pkgs,
  lib,
  ...
}:
let
  mcpo = pkgs.callPackage ../../../../pkgs/mcpo.nix { };
  ssePort = 30004;
  oapiPort = 30104;
in
{
  networking.firewall.interfaces = {
    librechat.allowedTCPPorts = [ ssePort ];
    tailscale0.allowedTCPPorts = [ ssePort ];
    ai.allowedTCPPorts = [ oapiPort ];
  };

  systemd.services.mcp-context7 = {
    description = "mcp-context7";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.mcp-proxy} --port ${toString ssePort} --host 0.0.0.0 -- ${lib.getExe pkgs.podman} run -i --rm context7-mcp";
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };

  systemd.services.mcpo-context7 = {
    description = "mcpo-context7";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe mcpo} --port ${toString oapiPort} --host 0.0.0.0 -- ${lib.getExe pkgs.podman} run -i --rm context7-mcp";
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };
}
