{ config, ... }:
let
  stackPath = "/etc/stacks/forgejo";
  my = config.services.my.forgejo;
  inherit (config.services) mesh;
  domain = "git.keyruu.de";
in
{
  sops.secrets = {
    forgejoLfsJwtSecret = { };
    forgejoInternalToken = { };
    forgejoJwtSecret = { };
  };

  sops.templates."forgejo.ini" = {
    restartUnits = [ "forgejo.service" ];
    owner = "git";
    group = "git";
    content = # ini
      ''
        APP_NAME = Forgejo
        RUN_MODE = prod
        APP_SLOGAN = This code is shitty because I wrote it!
        RUN_USER = git
        WORK_PATH = /data/gitea

        [repository]
        ROOT = /data/git/repositories

        [repository.local]
        LOCAL_COPY_PATH = /data/gitea/tmp/local-repo

        [repository.upload]
        TEMP_PATH = /data/gitea/uploads

        [server]
        APP_DATA_PATH = /data/gitea
        DOMAIN = ${domain}
        SSH_DOMAIN = git.lab.keyruu.de
        HTTP_PORT = 3000
        ROOT_URL = https://${domain}/
        DISABLE_SSH = false
        SSH_PORT = 222
        SSH_LISTEN_PORT = 22
        LFS_START_SERVER = true
        LFS_JWT_SECRET = ${config.sops.placeholder.forgejoLfsJwtSecret}
        OFFLINE_MODE = true

        [database]
        PATH = /data/gitea/gitea.db
        DB_TYPE = sqlite3
        HOST = localhost:3306
        NAME = gitea
        USER = root
        PASSWD =
        LOG_SQL = false
        SCHEMA =
        SSL_MODE = disable

        [indexer]
        ISSUE_INDEXER_PATH = /data/gitea/indexers/issues.bleve

        [session]
        PROVIDER_CONFIG = /data/gitea/sessions
        PROVIDER = file

        [picture]
        AVATAR_UPLOAD_PATH = /data/gitea/avatars
        REPOSITORY_AVATAR_UPLOAD_PATH = /data/gitea/repo-avatars

        [attachment]
        PATH = /data/gitea/attachments

        [log]
        MODE = console
        LEVEL = info
        ROOT_PATH = /data/gitea/log

        [security]
        INSTALL_LOCK = true
        SECRET_KEY = 
        REVERSE_PROXY_LIMIT = 1
        REVERSE_PROXY_TRUSTED_PROXIES = *
        INTERNAL_TOKEN = ${config.sops.placeholder.forgejoInternalToken}
        PASSWORD_HASH_ALGO = pbkdf2_hi

        [service]
        DISABLE_REGISTRATION = true
        REQUIRE_SIGNIN_VIEW = false
        REGISTER_EMAIL_CONFIRM = false
        ENABLE_NOTIFY_MAIL = true
        ALLOW_ONLY_EXTERNAL_REGISTRATION = false
        ENABLE_CAPTCHA = false
        DEFAULT_KEEP_EMAIL_PRIVATE = false
        DEFAULT_ALLOW_CREATE_ORGANIZATION = true
        DEFAULT_ENABLE_TIMETRACKING = true
        NO_REPLY_ADDRESS = noreply.localhost

        [lfs]
        PATH = /data/git/lfs

        [mailer]
        ENABLED        = true
        FROM           = forgejo@lab.keyruu.de
        PROTOCOL       = smtp+starttls
        SMTP_ADDR      = smtp.resend.com
        SMTP_PORT      = 587
        USER           = resend
        PASSWD         = ${config.sops.placeholder.resendApiKey}

        [openid]
        ENABLE_OPENID_SIGNIN = true
        ENABLE_OPENID_SIGNUP = true

        [cron.update_checker]
        ENABLED = true

        [repository.pull-request]
        DEFAULT_MERGE_STYLE = rebase
        DEFAULT_UPDATE_STYLE = rebase

        [repository.signing]
        DEFAULT_TRUST_MODEL = committer

        [oauth2]
        JWT_SECRET = ${config.sops.placeholder.forgejoJwtSecret}
      '';
  };

  users = {
    groups.git.gid = 1004;
    users = {
      git = {
        isSystemUser = true;
        uid = 1004;
        group = "git";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d ${stackPath}/data 0755 1004 1004"
  ];

  services.my.forgejo = {
    port = 3004;
    inherit domain;
    proxy = {
      enable = true;
      cert = {
        provided = false;
        host = domain;
      };
    };
    backup = {
      enable = true;
      paths = [ stackPath ];
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.forgejo.networkConfig = {
        driver = "bridge";
        podmanArgs = [ "--interface-name=forgejo" ];
      };
      containers = {
        forgejo = {
          containerConfig = {
            image = "codeberg.org/forgejo/forgejo:14.0.2";
            publishPorts = [
              "127.0.0.1:${toString my.port}:3000"
              "222:22"
            ];
            volumes = [
              "${stackPath}/data:/data"
              "${config.sops.templates."forgejo.ini".path}:/data/gitea/conf/app.ini:ro"
              "/etc/localtime:/etc/localtime:ro"
            ];
            environments = {
              USER_UID = "1004";
              USER_GID = "1004";
            };
            networks = [ networks.forgejo.ref ];
            networkAliases = [ "forgejo" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };
        anubis = {
          containerConfig = {
            image = "ghcr.io/techarohq/anubis:v1.25.0";
            publishPorts = [
              "${mesh.ip}:${toString my.port}:3000"
            ];
            environments = {
              BIND = ":3000";
              TARGET = "http://forgejo:3000";
              JWT_RESTRICTION_HEADER = "CF-Connecting-IP";
            };
            networks = [ networks.forgejo.ref ];
            networkAliases = [ "anubis" ];
          };
          serviceConfig = {
            Restart = "always";
          };
        };
      };
    };

  services.nginx.virtualHosts = {
    "git.lab.keyruu.de" = {
      useACMEHost = "lab.keyruu.de";
      forceSSL = true;
      inherit (config.services.nginx.virtualHosts."${my.domain}") locations;
    };
  };

  networking.hosts."127.0.0.1" = [ "git.lab.keyruu.de" ];
}
