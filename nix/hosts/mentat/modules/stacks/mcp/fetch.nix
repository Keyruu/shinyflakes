{
  pkgs,
  perSystem,
  lib,
  ...
}:
let
  ssePort = 30001;
  oapiPort = 30101;
in
{
  networking.firewall.interfaces = {
    librechat.allowedTCPPorts = [ ssePort ];
    tailscale0.allowedTCPPorts = [ ssePort ];
    ai.allowedTCPPorts = [ oapiPort ];
  };

  systemd.services.mcp-fetch = {
    description = "mcp-fetch";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.mcp-proxy} --port ${toString ssePort} --host 0.0.0.0 -- ${lib.getExe pkgs.podman} run -i --rm mcp/fetch";
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };

  systemd.services.mcpo-fetch = {
    description = "mcpo-fetch";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe perSystem.self.mcpo} --port ${toString oapiPort} --host 0.0.0.0 -- ${lib.getExe pkgs.podman} run -i --rm mcp/fetch";
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };
}
