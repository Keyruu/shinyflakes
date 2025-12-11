_:
let
  sleipnirIp = "\${hcloud_server.sleipnir.ipv4_address}";
  pegasusIp = "\${hcloud_server.pegasus.ipv4_address}";
in
{
  imports = [ ./modules/dns.nix ];

  cloudflare.zones = {
    "keyruu.de" = {
      zoneId = "\${cloudflare_zone.keyruu-de.id}";
      records = {
        a = {
          sleipnir = {
            content = sleipnirIp;
            cnames = [
              "sorryihavetodothis"
              "rybbit"
              "files"
              "cache"
              "n8n"
              "garage"
              "s3"
              "*"
            ];
          };
          coolify = {
            content = pegasusIp;
            cnames = [
              "fm"
              "oblivion"
              "@"
            ];
          };
        };

        cname = {
          "protonmail._domainkey" = {
            content = "protonmail.domainkey.d4fe7cawhbkxd6tvmam7kymmpcxi4uqrn2rjc7oavfcgivkbtlssq.domains.proton.ch";
            proxied = false;
          };
          "protonmail2._domainkey" = {
            content = "protonmail2.domainkey.d4fe7cawhbkxd6tvmam7kymmpcxi4uqrn2rjc7oavfcgivkbtlssq.domains.proton.ch";
            proxied = false;
          };
          "protonmail3._domainkey" = {
            content = "protonmail3.domainkey.d4fe7cawhbkxd6tvmam7kymmpcxi4uqrn2rjc7oavfcgivkbtlssq.domains.proton.ch";
            proxied = false;
          };
          "key1._domainkey" = {
            content = "key1.keyruu.de._domainkey.migadu.com.";
            proxied = false;
          };
          "key2._domainkey" = {
            content = "key2.keyruu.de._domainkey.migadu.com.";
            proxied = false;
          };
          "key3._domainkey" = {
            content = "key3.keyruu.de._domainkey.migadu.com.";
            proxied = false;
          };
          "autoconfig" = {
            content = "autoconfig.migadu.com.";
            proxied = false;
          };
        };

        mx = {
          "@" = [
            {
              content = "aspmx1.migadu.com";
              priority = 10;
              comment = "10";
            }
            {
              content = "aspmx2.migadu.com";
              priority = 20;
              comment = "20";
            }
          ];
          "*" = [
            {
              content = "aspmx1.migadu.com";
              priority = 10;
              comment = "mx1";
            }
            {
              content = "aspmx2.migadu.com";
              priority = 20;
              comment = "mx2";
            }
          ];
          "send.lab" = [
            {
              content = "feedback-smtp.us-east-1.amazonses.com";
              priority = 10;
            }
          ];
        };

        txt = {
          "@" = [
            {
              content = "protonmail-verification=62673f2072dc24b4ddfbd6b529e4a739015bf114";
              comment = "protonmail-verification";
            }
            {
              content = "v=spf1 include:spf.migadu.com -all";
              comment = "spf";
            }
            {
              content = "hosted-email-verify=1wxdfhns";
              comment = "migadu-verification";
            }
          ];
          "_dmarc" = [
            {
              content = "v=DMARC1; p=reject; rua=mailto:003e8edaf3ba4b5c87763b1d392a3ae4@dmarc-reports.cloudflare.net,mailto:dmarc@keyruu.de";
            }
          ];
          "resend._domainkey.lab" = [
            {
              content = "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCbrRffh6/aF6JKZu50SLBE2fJap8FZUqVgl2ZFrd5H9qm1R36UAB4vnXKTP1FYjxg50uEWzOHeUSylzCHmPJElAl8kC0kdI8z2v7FT3NF8HuX3P3FoeXcibj7ryNWgYbC7MG2yZz4KSLS9cbXzAY8h4BqieW5IlkAYMKIcDgGpRwIDAQAB";
            }
          ];
          "send.lab" = [
            {
              content = "v=spf1 include:amazonses.com ~all";
            }
          ];
        };
      };
    };

    "peeraten.net" = {
      zoneId = "\${cloudflare_zone.peeraten-net.id}";
      records = {
        cname = {
          sleipnir = {
            content = "sleipnir.keyruu.de";
            cnames = [
              "auth"
              "calendar"
              "hass"
              "headscale"
              "map"
              "traccar"
              "owntracks"
            ];
          };
        };
      };
    };

    "buymeaspezi.com" = {
      zoneId = "\${cloudflare_zone.buymeaspezi-com.id}";
      records = {
        cname = {
          "@" = {
            content = "coolify.keyruu.de";
          };
        };

        txt = {
          "@" = [
            {
              content = "v=spf1 +a +mx ?all";
              comment = "spf";
            }
            {
              content = "google-site-verification=Xp1JOYijsYthBvjSkm2CNNxYkGNTXMw4aUCOABtxfi0";
              comment = "google-site-verification";
            }
          ];
        };
      };
    };
  };
}
