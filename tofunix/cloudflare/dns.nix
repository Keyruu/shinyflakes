{ ref, ... }:
{
  imports = [ ./modules/dns.nix ];

  cloudflare.zones = {
    "keyruu.de" = {
      zoneId = ref.cloudflare_zone.keyruu-de.id;
      records = {
        a = {
          sleipnir = {
            content = ref.hcloud_server.sleipnir.ipv4_address;
            proxied = false;
            cnames = [
              "sorryihavetodothis"
              "rybbit"
              "files"
              "cache"
              "n8n"
              "garage"
              "s3"
              "atuin"
              "git"
              "*"
            ];
          };
          coolify = {
            content = ref.hcloud_server.pegasus.ipv4_address;
            cnames = [
              "fm"
              "oblivion"
              "@"
            ];
          };
        };

        cname = {
          "key1._domainkey" = {
            content = "key1.keyruu.de._domainkey.migadu.com";
            proxied = false;
          };
          "key2._domainkey" = {
            content = "key2.keyruu.de._domainkey.migadu.com";
            proxied = false;
          };
          "key3._domainkey" = {
            content = "key3.keyruu.de._domainkey.migadu.com";
            proxied = false;
          };
          "autoconfig" = {
            content = "autoconfig.migadu.com";
            proxied = false;
          };
        };

        mx = {
          "@" = {
            "10" = {
              content = "aspmx1.migadu.com";
              priority = 10;
            };
            "20" = {
              content = "aspmx2.migadu.com";
              priority = 20;
            };
          };
          "*" = {
            mx1 = {
              content = "aspmx1.migadu.com";
              priority = 10;
            };
            mx2 = {
              content = "aspmx2.migadu.com";
              priority = 20;
            };
          };
          "send.lab".ses = {
            content = "feedback-smtp.us-east-1.amazonses.com";
            priority = 10;
          };
        };

        txt = {
          "@" = {
            protonmail-verification.content = "protonmail-verification=62673f2072dc24b4ddfbd6b529e4a739015bf114";
            spf.content = "v=spf1 include:spf.migadu.com -all";
            migadu-verification.content = "hosted-email-verify=1wxdfhns";
          };
          "_dmarc".dmarc.content =
            "v=DMARC1; p=reject; rua=mailto:003e8edaf3ba4b5c87763b1d392a3ae4@dmarc-reports.cloudflare.net,mailto:dmarc@keyruu.de";
          "resend._domainkey.lab".resend-domainkey.content =
            "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCbrRffh6/aF6JKZu50SLBE2fJap8FZUqVgl2ZFrd5H9qm1R36UAB4vnXKTP1FYjxg50uEWzOHeUSylzCHmPJElAl8kC0kdI8z2v7FT3NF8HuX3P3FoeXcibj7ryNWgYbC7MG2yZz4KSLS9cbXzAY8h4BqieW5IlkAYMKIcDgGpRwIDAQAB";
          "send.lab".spf.content = "v=spf1 include:amazonses.com ~all";
        };
      };
    };

    "peeraten.net" = {
      zoneId = ref.cloudflare_zone.peeraten-net.id;
      records.cname = {
        sleipnir = {
          content = "sleipnir.keyruu.de";
          proxied = false;
          cnames = [
            "auth"
            "calendar"
            "hass"
            "headscale"
            "map"
            "traccar"
            "owntracks"
            "service"
          ];
        };
        mesh = {
          content = "sleipnir.peeraten.net";
          proxied = false;
        };
      };
    };

    "buymeaspezi.com" = {
      zoneId = ref.cloudflare_zone.buymeaspezi-com.id;
      records = {
        cname."@".content = "coolify.keyruu.de";

        txt."@" = {
          spf.content = "v=spf1 +a +mx ?all";
          google-site-verification.content = "google-site-verification=Xp1JOYijsYthBvjSkm2CNNxYkGNTXMw4aUCOABtxfi0";
        };
      };
    };
  };
}
