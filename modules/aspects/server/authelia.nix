# Authelia aspect — SSO + OIDC consumer of den.people data and
# per-service oidc-config quirks.
#
# Three derivations:
#   1. <service>_users groups:  members derived from
#      den.people.<name>.service-access
#   2. <service>_access policies:  one_factor rule for each group
#   3. OIDC clients:  per-service client config from the oidc-config
#      quirk (redirect URIs, scopes, auth method, clientId). Secret
#      wired via SOPS placeholder <clientId>ClientSecret.
#
# Replaces the hand-rolled authorization_policies + clients blocks
# in nix/hosts/prime/modules/authelia.nix and the users.yml seed in
# nix/modules/private/authelia.nix.
#
# ponytail: per-service OIDC client profile (redirect URIs, PKCE, scopes)
# lives in the oidc-config quirk emitted by each service aspect. The
# service file is the single source of truth for its OIDC config.
{ config, lib, ... }:
{
  den.aspects.server.authelia = {
    nixos =
      { config, lib, oidc-config, ... }:
      let
        # Flatten all persons' service-access into one tagged list:
        #   [ { person = "lucas"; service = "immich"; } ... ]
        allAccess = lib.concatLists (lib.mapAttrsToList (person: p:
          map (svc: { inherit person; service = svc; }) p.service-access
        ) config.den.people);

        # Unique service names referenced by any grant.
        services = lib.unique (map (entry: entry.service) allAccess);

        buildPolicy = service: {
          default_policy = "deny";
          rules = [
            {
              policy = "one_factor";
              subject = "group:${service}_users";
            }
          ];
        };

        # `oidc-config` quirk entries are flat attrsets:
        # { name; enable; clientId; scopes; redirectPath; tokenEndpointAuthMethod; domain; redirectUri }.
        clientFor = clientId:
          lib.head (lib.filter (c: c.clientId == clientId) oidc-config);
      in
      {
        # Declare SOPS secrets for each OIDC client id.
        sops.secrets = lib.listToAttrs (
          map (c: lib.nameValuePair "${c.clientId}ClientSecret" { }) oidc-config
        );

        services.authelia.instances.main.settings.identity_providers.oidc = {
          authorization_policies = lib.genAttrs services buildPolicy;
          clients = lib.genAttrs (map (c: c.clientId) oidc-config) (
            clientId: {
              client_id = clientId;
              client_name = clientId;
              client_secret = config.sops.placeholder."${clientId}ClientSecret";
              authorization_policy = "${clientId}_access";
              inherit (clientFor clientId) scopes redirectUri tokenEndpointAuthMethod;
            }
          );
        };
      };
  };
}
