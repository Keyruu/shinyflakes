{
  config,
  pkgs,
  lib,
  ...
}:
let
  mcp-proxy = pkgs.callPackage ../../../../pkgs/mcp-proxy.nix { };
in
{
  sops.secrets = {
    atlassianUrl.owner = "root";
    atlassianUsername.owner = "root";
    atlassianToken.owner = "root";
  };

  sops.templates."mcp-atlassian.env".content = # sh
    ''
      CONFLUENCE_URL=${config.sops.placeholder.atlassianUrl}/wiki
      CONFLUENCE_USERNAME=${config.sops.placeholder.atlassianUsername}
      CONFLUENCE_API_TOKEN=${config.sops.placeholder.atlassianToken}
      JIRA_URL=${config.sops.placeholder.atlassianUrl}/
      JIRA_USERNAME=${config.sops.placeholder.atlassianUsername}
      JIRA_API_TOKEN=${config.sops.placeholder.atlassianToken}
    '';

  networking.firewall.interfaces.podman3.allowedTCPPorts = [ 30002 ];

  systemd.services.mcp-atlassian = {
    description = "mcp-atlassian";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = ''
        ${lib.getExe mcp-proxy} --port 30002 --host 0.0.0.0 --pass-environment -- ${lib.getExe pkgs.podman} run -i --rm \
        -e CONFLUENCE_URL \
        -e CONFLUENCE_USERNAME \
        -e CONFLUENCE_API_TOKEN \
        -e JIRA_URL \
        -e JIRA_USERNAME \
        -e JIRA_API_TOKEN \
        ghcr.io/sooperset/mcp-atlassian:latest
      '';
      User = "root";
      Group = "root";
      Restart = "always";
      EnvironmentFile = config.sops.templates."mcp-atlassian.env".path;
    };
  };
}
