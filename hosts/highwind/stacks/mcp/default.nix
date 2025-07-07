{ pkgs, ... }:
let
  mcpo = pkgs.callPackage ../../../../pkgs/mcpo.nix { };
in
{
  environment.systemPackages = [
    pkgs.mcp-proxy
    mcpo
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
