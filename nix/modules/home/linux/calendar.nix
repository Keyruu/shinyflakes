{
  config,
  pkgs,
  perSystem,
  ...
}:
{
  home.packages = with pkgs; [
    gcalcli
    perSystem.self.nextmeeting
  ];

  sops.secrets = {
    gcalConfig.path = "/home/${config.home.username}/.config/gcalcli/config.toml";
    gcalUrl = { };
    gmailClientId = { };
    gmailClientSecret = { };
    sharedCalendarUser = { };
    sharedCalendarPassword = { };
  };

  home.file.".config/nextmeeting/config.toml".text = # toml
    ''
      [nextmeeting]
      max-title-length = 30
      notify-min-before-events = 5
      notify-offsets = [15, 5]
      notify-icon = calendar
      hour-separator = ":"
      privacy = false
    '';

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
          # urlCommand = [
          #   "cat"
          #   config.sops.secrets.gcalUrl.path
          # ];
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

  # Khal configuration
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
}
