{
  config,
  flake,
  perSystem,
  ...
}:
let
  my = config.services.my.jellyfin;
  inherit (config.virtualisation.quadlet) containers;
  inherit (flake.lib) quadlet;
in
{
  sops.secrets.jellyfinClientSecret = { };

  # SSO-Auth plugin config, see https://www.authelia.com/integration/openid-connect/clients/jellyfin/
  sops.templates."jellyfin-sso.xml" = {
    restartUnits = [ (quadlet.service containers.jellyfin) ];
    content = ''
      <?xml version="1.0" encoding="utf-8"?>
      <PluginConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <SamlConfigs />
        <OidConfigs>
          <item>
            <key>
              <string>authelia</string>
            </key>
            <value>
              <PluginConfiguration>
                <OidEndpoint>https://auth.peeraten.net</OidEndpoint>
                <OidClientId>jellyfin</OidClientId>
                <OidSecret>${config.sops.placeholder.jellyfinClientSecret}</OidSecret>
                <Enabled>true</Enabled>
                <EnableAuthorization>true</EnableAuthorization>
                <EnableAllFolders>true</EnableAllFolders>
                <EnabledFolders />
                <AdminRoles>
                  <string>jellyfin_admins</string>
                </AdminRoles>
                <Roles>
                  <string>jellyfin_users</string>
                  <string>jellyfin_admins</string>
                </Roles>
                <EnableFolderRoles>false</EnableFolderRoles>
                <EnableLiveTvRoles>false</EnableLiveTvRoles>
                <EnableLiveTv>false</EnableLiveTv>
                <EnableLiveTvManagement>false</EnableLiveTvManagement>
                <LiveTvRoles />
                <LiveTvManagementRoles />
                <FolderRoleMappings />
                <RoleClaim>groups</RoleClaim>
                <OidScopes>
                  <string>groups</string>
                </OidScopes>
                <CanonicalLinks></CanonicalLinks>
                <DisableHttps>false</DisableHttps>
                <DoNotValidateEndpoints>false</DoNotValidateEndpoints>
                <DoNotValidateIssuerName>false</DoNotValidateIssuerName>
                <SchemeOverride>https</SchemeOverride>
              </PluginConfiguration>
            </value>
          </item>
        </OidConfigs>
      </PluginConfiguration>
    '';
  };

  services.my.jellyfin = {
    zfs = true;
    port = 8096;
    domain = "jellyfin.lab.keyruu.de";
    proxy.enable = true;
    backup.enable = true;
    stack = {
      enable = true;
      directories = [
        "config"
        "cache"
      ];
      security.enable = false;

      containers = {
        jellyfin = {
          containerConfig = {
            image = "ghcr.io/jellyfin/jellyfin:10.11.11";
            volumes = [
              "${my.stack.path}/config:/config"
              "${perSystem.self.jellyfin-sso-plugin}:/config/plugins/sso-authentication:ro"
              "${config.sops.templates."jellyfin-sso.xml".path}:/config/plugins/configurations/SSO-Auth.xml:ro"
              "${my.stack.path}/cache:/cache"
              "/main/media:/media"
            ];
            publishPorts = [
              "127.0.0.1:${toString my.port}:8096"
              "${config.services.mesh.ip}:${toString my.port}:8096"
            ];
          };
        };
      };
    };
  };
}
