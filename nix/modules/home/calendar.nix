{
  config,
  pkgs,
  ...
}:
let
  next-event = pkgs.writeShellScriptBin "next-event" ''
    five_min_ago=$(date -d '-5 minutes' '+%Y-%m-%d %H:%M')
    khal list "$five_min_ago" 24h \
      --day-format "" \
      --notstarted \
      --format "{start-end-time-style} {title}{repeat-symbol}" |
      grep -Ev '↦|↔ |⇥' |
      grep -v '^ ' |
      sed -e 's/&/\&amp;/g' |
      head -n 1 || echo "No events"
  '';
  next-events = pkgs.writeShellScriptBin "next-events" ''
    khal list "$(date '+%Y-%m-%d %H:%M')" 7d \
      --day-format "<i>{name}, {date}</i>" \
      -f "{start-time}-{end-time} <b>{title}</b> ({location})" |
      grep -Ev '↦|↔ |⇥' |
      grep -v '^ ' |
      sed -e 's/&/\&amp;/g'
  '';

  noctalia-event = pkgs.writeShellScriptBin "noctalia-event" ''
    text=$(next-event | awk -v len=40 '{ if (length($0) > len) print substr($0, 1, len-3) "..."; else print; }')
    tooltip="<div align='left'>$(next-events | sed -z 's/\n/<br\/>/g')</div>"

    jq -nc \
      --arg text "$text" \
      --arg tooltip "$tooltip" \
      '{text: $text, tooltip: $tooltip}'
  '';

  waybar-khal = pkgs.writeShellScriptBin "waybar-khal" ''
    five_min_ago=$(date -d '-5 minutes' '+%Y-%m-%d %H:%M')

    next_event=$(next-event)

    tooltip=$(next-events)

    jq -nc \
      --arg text "$next_event" \
      --arg tooltip "$tooltip" \
      '{text: $text, tooltip: $tooltip}'
  '';

  khal-notify = pkgs.writeShellScriptBin "khal-notify" ''
    now=$(date '+%Y-%m-%d %H:%M')
    events=$(khal list "$now" 15m \
      --day-format "" \
      --notstarted \
      --format "|{all-day}|• {start-time} <i>{title}</i> ({location})" |
      grep -v '^ ' |
      grep -v '^|True|' |
      sed 's/^|False|//')

    if [ -n "$events" ]; then
      notify-send -u normal -i calendar "Upcoming events" "$events"
    fi
  '';

  khal-open-meet = pkgs.writeShellScriptBin "khal-open-meet" ''
    in_five_min=$(date -d '+5 minutes' '+%Y-%m-%d %H:%M')
    meet_url=$(khal at $in_five_min 2>/dev/null | grep -oP 'https://meet\.google\.com/[a-z0-9-]+' | head -n 1)
    if [ -n "$meet_url" ]; then
      ${pkgs.xdg-utils}/bin/xdg-open "$meet_url"
    else
      notify-send -i google-meet 'Could not find a meet URL'
    fi
  '';
in
{
  home.packages = [
    next-event
    next-events
    noctalia-event
    waybar-khal
    khal-notify
    khal-open-meet
  ];

  sops.secrets = {
    gmailClientId = { };
    gmailClientSecret = { };
    sharedCalendarUser = { };
    sharedCalendarPassword = { };
  };

  # Calendar accounts
  accounts.calendar = {
    basePath = ".local/share/calendars";

    accounts = {
      work = {
        primary = false;
        primaryCollection = "work";

        remote.type = "google_calendar";

        local = {
          type = "filesystem";
        };

        vdirsyncer = {
          enable = true;
          collections = [
            "from a"
            "from b"
          ];
          metadata = [
            "color"
          ];
          clientIdCommand = [
            "cat"
            config.sops.secrets.gmailClientId.path
          ];
          clientSecretCommand = [
            "cat"
            config.sops.secrets.gmailClientSecret.path
          ];
          tokenFile = "vdirsyncer-gmail-token";
        };

        khal = {
          enable = true;
          priority = 10;
          type = "discover";
        };
      };

      shared = {
        primary = false;
        primaryCollection = "private";

        remote = {
          type = "caldav";
          url = "https://calendar.peeraten.net/";
          passwordCommand = [
            "cat"
            config.sops.secrets.sharedCalendarPassword.path
          ];
        };

        local = {
          type = "filesystem";
        };

        vdirsyncer = {
          enable = true;
          collections = [
            "from a"
            "from b"
          ];
          metadata = [
            "color"
          ];
          userNameCommand = [
            "cat"
            config.sops.secrets.sharedCalendarUser.path
          ];
        };

        khal = {
          enable = true;
          priority = 20;
          type = "discover";
        };
      };
    };
  };

  programs.khal = {
    enable = true;
    locale = {
      timeformat = "%H:%M";
      dateformat = "%Y-%m-%d";
      longdateformat = "%Y-%m-%d";
      datetimeformat = "%Y-%m-%d %H:%M";
      longdatetimeformat = "%Y-%m-%d %H:%M";
    };
    settings = {
      default = {
        # this is so stupid
        default_calendar = "work1";
        timedelta = "5d";
      };
      view = {
        agenda_event_format = "{calendar-color}{cancelled}{start-end-time-style} {title}{repeat-symbol}";
      };
    };
  };

  programs.vdirsyncer = {
    enable = true;
  };
  services.vdirsyncer = {
    enable = true;
    frequency = "*:0/5"; # Sync every 5 minutes
  };

  systemd.user.services.khal-notify = {
    Unit = {
      Description = "Check for upcoming calendar events";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${khal-notify}/bin/khal-notify";
    };
  };

  systemd.user.timers.khal-notify = {
    Unit = {
      Description = "Timer for calendar notifications";
    };
    Timer = {
      OnCalendar = "*:0/5"; # Check every 5 minutes
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
