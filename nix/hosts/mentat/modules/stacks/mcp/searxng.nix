{
  config,
  perSystem,
  pkgs,
  lib,
  ...
}:
let
  ssePort = 30003;
  oapiPort = 30103;

  # renovate: datasource=docker depName=isokoliuk/mcp-searxng
  mcpVersion = "0.9.1";
in
{
  networking.firewall.interfaces = {
    librechat.allowedTCPPorts = [ ssePort ];
    "${config.services.mesh.interface}".allowedTCPPorts = [ ssePort ];
    ai.allowedTCPPorts = [ oapiPort ];
  };

  systemd.services.mcp-searxng = {
    description = "mcp-searxng";
    wantedBy = [ "multi-user.target" ];
    environment = {
      SEARXNG_URL = "http://127.0.0.1:4899";
    };
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.mcp-proxy} --port ${toString ssePort} --host 0.0.0.0 --pass-environment -- ${lib.getExe pkgs.podman} run -i --rm -e SEARXNG_URL --network host isokoliuk/mcp-searxng:${mcpVersion}";
      User = "root";
      Group = "root";
      Restart = "always";
    };
  };

  # systemd.services.mcpo-searxng = {
  #   description = "mcpo-searxng";
  #   wantedBy = [ "multi-user.target" ];
  #   environment = {
  #     SEARXNG_URL = "http://127.0.0.1:4899";
  #   };
  #   serviceConfig = {
  #     ExecStart = "${lib.getExe perSystem.self.mcpo} --port ${toString oapiPort} --host 0.0.0.0 -- ${lib.getExe pkgs.podman} run -i --rm -e SEARXNG_URL --network host isokoliuk/mcp-searxng:${mcpVersion}";
  #     User = "root";
  #     Group = "root";
  #     Restart = "always";
  #   };
  # };
}
