{ pkgs, ... }:
let
  mcp-proxy = pkgs.callPackage ../../../../pkgs/mcp-proxy.nix { };
in
{
  environment.systemPackages = [
    mcp-proxy
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
  ];
}
