{
  config,
  pkgs,
  lib,
  ...
}:
let
  ssePort = 30000;
  oapiPort = 30100;

  # renovate: datasource=docker depName=ghcr.io/github/github-mcp-server
  mcpVersion = "v0.31.0";
in
{
  sops.secrets.githubToken.owner = "root";
  sops.templates."mcp-github.env" = {
    restartUnits = [
      "mcp-github.service"
    ];
    content = # sh
      ''
        GITHUB_PERSONAL_ACCESS_TOKEN=${config.sops.placeholder.githubToken}
      '';
  };

  networking.firewall.interfaces = {
    librechat.allowedTCPPorts = [ ssePort ];
    "${config.services.mesh.interface}".allowedTCPPorts = [ ssePort ];
    ai.allowedTCPPorts = [ oapiPort ];
  };

  systemd.services.mcp-github = {
    description = "mcp-github";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.mcp-proxy} --port ${toString ssePort} --host 0.0.0.0 --pass-environment -- ${lib.getExe pkgs.podman} run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server:${mcpVersion}";
      User = "root";
      Group = "root";
      Restart = "always";
      EnvironmentFile = config.sops.templates."mcp-github.env".path;
    };
  };

  # systemd.services.mcpo-github = {
  #   description = "mcpo-github";
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     ExecStart = "${lib.getExe perSystem.self.mcpo} --port ${toString oapiPort} --host 0.0.0.0 -- ${lib.getExe pkgs.podman} run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server:${mcpVersion}";
  #     User = "root";
  #     Group = "root";
  #     Restart = "always";
  #     EnvironmentFile = config.sops.templates."mcp-github.env".path;
  #   };
  # };
}
