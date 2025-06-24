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
  sops.secrets.githubToken.owner = "root";
  sops.templates."mcp-github.env".content = # sh
    ''
      GITHUB_PERSONAL_ACCESS_TOKEN=${config.sops.placeholder.githubToken}
    '';

  networking.firewall.interfaces.podman3.allowedTCPPorts = [ 30000 ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 30000 ];

  systemd.services.mcp-github = {
    description = "mcp-github";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${lib.getExe mcp-proxy} --port 30000 --host 0.0.0.0 --pass-environment -- ${lib.getExe pkgs.podman} run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server:main";
      User = "root";
      Group = "root";
      Restart = "always";
      EnvironmentFile = config.sops.templates."mcp-github.env".path;
    };
  };
}
