# Edge protection: GeoLite2 DB + geoblock snippet for caddy vhosts,
# fail2ban jails on caddy access logs. Bans must happen here — backends
# on mentat only ever see prime's mesh IP.
{ config, ... }:
{
  sops.secrets.maxmindLicenseKey = { };

  # matcher uses caddy's resolved client IP, so it also works behind
  # cloudflare-only vhosts (trusted_proxies + Cf-Connecting-Ip)
  services.caddy.extraConfig = ''
    (geoblock-de) {
      @geo-allowed {
        maxmind_geolocation {
          db_path /var/lib/GeoIP/GeoLite2-Country.mmdb
          allow_countries DE
        }
      }
    }
  '';

  services.geoipupdate = {
    enable = true;
    settings = {
      AccountID = 1384453;
      EditionIDs = [ "GeoLite2-Country" ];
      LicenseKey = config.sops.secrets.maxmindLicenseKey.path;
    };
  };

  # caddy's maxmind matcher fails to provision without the mmdb
  systemd.services.caddy = {
    wants = [ "geoipupdate.service" ];
    after = [ "geoipupdate.service" ];
  };

  # 401 on the login endpoint in caddy's JSON access log = jellyfin's
  # "Authentication request has been denied", but with the real client IP.
  # {NONE} datepattern = ban timestamps are "time of read"; on
  # fail2ban restart old log lines may re-ban — harmless with 1h bantime
  environment.etc."fail2ban/filter.d/jellyfin-caddy.local".text = ''
    [Definition]
    failregex = ^.*"client_ip":"<HOST>".*"uri":"/Users/AuthenticateByName".*"status":401
    datepattern = {NONE}
  '';

  services.fail2ban.jails.jellyfin.settings = {
    filter = "jellyfin-caddy";
    logpath = "/var/log/caddy/access-tv.peeraten.net.log";
    maxretry = 5;
    findtime = "10m";
    bantime = "1h";
  };
}
