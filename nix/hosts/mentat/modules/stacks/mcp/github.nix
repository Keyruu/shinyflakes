{
  config,
  pkgs,
  perSystem,
  lib,
  ...
}:
let
  ssePort = 30000;
  oapiPort = 30100;

  # renovate: datasource=docker depName=ghcr.io/github/github-mcp-server
  mcpVersion = "0.26.3";
in
{
  sops.secrets.githubToken.owner = "root";
  sops.templates."mcp-github.env" = {
    restartUnits = [
      "mcp-github.service"
      "mcpo-github.service"
    ];
    content = # sh
      ''
        GITHUB_PERSONAL_ACCESS_TOKEN=${config.sops.placeholder.githubToken}
      '';
  };

  networking.firewall.interfaces = {
    librechat.allowedTCPPorts = [ ssePort ];
    tailscale0.allowedTCPPorts = [ ssePort ];
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

  systemd.services.mcpo-github = {
    description = "mcpo-github";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe perSystem.self.mcpo} --port ${toString oapiPort} --host 0.0.0.0 -- ${lib.getExe pkgs.podman} run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server:${mcpVersion}";
      User = "root";
      Group = "root";
      Restart = "always";
      EnvironmentFile = config.sops.templates."mcp-github.env".path;
    };
  };
}
