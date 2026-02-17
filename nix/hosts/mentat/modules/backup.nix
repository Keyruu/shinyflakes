{ config, pkgs, ... }:
{
  users.groups.restic = { };
  users.users.restic = {
    isSystemUser = true;
    group = "restic";
  };
  sops = {
    secrets = {
      resticHtpasswd = {
        owner = "restic";
        group = "restic";
      };
      resticPassword = { };
      resticServerPassword = { };
      resticB2Password = { };
      b2MentatResticAccessKey = { };
      b2MentatResticSecretKey = { };
    };
    templates = {
      "resticRepo".content =
        "rest:http://lucas:${config.sops.placeholder.resticServerPassword}@127.0.0.1:8004/restic";
      "restic-b2.env".content = # sh
        ''
          RESTIC_REPOSITORY=rest:http://lucas:${config.sops.placeholder.resticServerPassword}@127.0.0.1:8004/restic
          RESTIC_PASSWORD_FILE=${config.sops.resticPassword.path}
          RESTIC_REPOSITORY2=s3:https://s3.eu-central-003.backblazeb2.com/keyruu-restic-backup/restic
          RESTIC_PASSWORD_FILE2=${config.sops.resticB2Password.path}
          AWS_ACCESS_KEY_ID=${config.sops.placeholder.b2MentatResticAccessKey}
          AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.b2MentatResticSecretKey}
        '';
    };
  };

  services.restic = {
    defaultRepoFile = config.sops.templates."resticRepo".path;
    server = {
      enable = true;
      dataDir = "/main/backup";
      listenAddress = "8004";
      htpasswd-file = config.sops.secrets.resticHtpasswd.path;
    };
  };

  systemd.services.restic-copy-to-b2 = {
    description = "Copy restic snapshots to B2";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";
      EnvironmentFile = config.sops.templates."restic-b2.env".path;
    };

    script =
      let
        resticCmd = "${pkgs.restic}/bin/restic";
      in
      # sh
      ''
        ${resticCmd} -r "$RESTIC_REPOSITORY2" \
          --password-file "$RESTIC_PASSWORD_FILE2" \
          cat config 2>/dev/null || \
        ${resticCmd} -r "$RESTIC_REPOSITORY2" \
          --password-file "$RESTIC_PASSWORD_FILE2" \
          init

        ${resticCmd} copy \
          --repo2 "$RESTIC_REPOSITORY2" \
          --password-file2 "$RESTIC_PASSWORD_FILE2"

        ${resticCmd} -r "$RESTIC_REPOSITORY2" \
          --password-file "$RESTIC_PASSWORD_FILE2" \
          forget --prune \
          --keep-weekly 4 \
          --keep-monthly 4 \
          --keep-yearly 2
      '';
  };

  systemd.timers.restic-copy-to-b2 = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  networking.firewall.extraCommands = "iptables -A INPUT -p tcp -s 100.67.0.1 --dport ${config.services.restic.server.listenAddress} -j ACCEPT";
}
