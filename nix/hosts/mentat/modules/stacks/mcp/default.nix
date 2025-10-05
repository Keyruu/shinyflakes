{ pkgs, perSystem, ... }:
{
  environment.systemPackages = [
    pkgs.mcp-proxy
    perSystem.self.mcpo
  ];

  users.users.mcp = {
    isSystemUser = true;
    group = "mcp";
    extraGroups = [ "podman" ];
    description = "User for MCP services";
  };

  users.groups.mcp = { };

  imports = [
    ./github.nix
    ./fetch.nix
    ./atlassian.nix
    ./searxng.nix
    # ./context7.nix
  ];
}
