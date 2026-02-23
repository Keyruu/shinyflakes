{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.mcp-proxy
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
    ./atlassian.nix
    ./searxng.nix
    ./kagi.nix
  ];
}
