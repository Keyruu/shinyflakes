{
  config,
  pkgs,
  perSystem,
  ...
}:
{
  home.shellAliases.tbkeys = "cat ${config.xdg.configHome}/tbkeys/mainkeys.json | wl-copy";

  xdg.configFile."tbkeys/mainkeys.json".text = builtins.toJSON {
    "j" = "cmd:cmd_nextMsg";
    "k" = "cmd:cmd_previousMsg";
    "o" = "cmd:cmd_openMessage";
    "f" = "cmd:cmd_forward";
    "#" = "cmd:cmd_delete";
    "r" = "cmd:cmd_reply";
    "a" = "cmd:cmd_replyall";
    "x" = "cmd:cmd_archive";
    "c" = "func:MsgNewMessage";
    "u" = "tbkeys:closeMessageAndRefresh";
    "G" = "cmd:cmd_nextUnreadMsg";
    "s" = "cmd:cmd_markAsRead";
    "S" = "cmd:cmd_markAllRead";
    "!" = "cmd:cmd_markAsFlagged";
    "/" = "cmd:cmd_search";
    "d" = "cmd:cmd_delete";
  };

  programs = {
    thunderbird = {
      enable = true;
      settings = {
        "privacy.donottrackheader.enabled" = true;
        "mail.identity.default.reply_on_top" = 1;
        "mail.identity.default.sig_bottom" = false;
      };
      profiles = rec {
        private = {
          isDefault = true;
          extensions = with perSystem.rycee.thunderbird-addons; [
            tbkeys
          ];
        };
        work = {
          inherit (private) extensions;
        };
      };
    };

    aerc = {
      enable = true;

      extraConfig = {
        compose = {
          edit-headers = true;
          file-picker-cmd = "fzf --multi --query=%s";
          reply-to-self = false;
        };

        filters = {
          ".headers" = "colorize";
          "text/calendar" = "calendar";
          "text/html" = "! html -o display_link_number=true | colorize";
          "text/plain" = "colorize";
          "text/*" = "${pkgs.bat}/bin/bat -fP --file-name $AERC_FILENAME";
          "message/delivery-status" = "colorize";
          "message/rfc822" = "colorize";
          "application/pdf" = "${pkgs.zathura}/bin/zathura -";
          "application/x-sh" = "${pkgs.bat}/bin/bat -fP -l sh";
          "audio/*" = "${pkgs.mpv}/bin/mpv -";
        };

        general = {
          default-menu-cmd = "${pkgs.fzf}/bin/fzf";
          enable-osc8 = true;
          pgp-provider = "gpg";
          unsafe-accounts-conf = true;
        };

        viewer = {
          header-layout = "From|To,Cc|Bcc,Date,Subject,DKIM+|SPF+|DMARC+";
        };

        ui = {
          tab-title-account = "{{.Account}} {{if .Unread}}({{.Unread}}){{end}}";
          fuzzy-complete = true;
          mouse-enabled = true;
          msglist-scroll-offset = 5;
          show-thread-context = true;
          threading-enabled = true;
          spinner = "◜,◠,◝,◞,◡,◟";
        };
      };

      extraBinds = {
        global = {
          "<C-k>" = ":prev-tab<Enter>";
          "<C-j>" = ":next-tab<Enter>";
          "?" = ":help keys<Enter>";
          "<C-c>" = ":prompt 'Quit?' quit<Enter>";
          "<C-q>" = ":prompt 'Quit?' quit<Enter>";
        };

        messages = {
          "q" = ":prompt 'Quit?' quit<Enter>";
          "j" = ":next<Enter>";
          "k" = ":prev<Enter>";
          "<C-d>" = ":next 50%<Enter>";
          "<C-u>" = ":prev 50%<Enter>";
          "<PgDn>" = ":next 100%<Enter>";
          "<PgUp>" = ":prev 100%<Enter>";
          "g" = ":select 0<Enter>";
          "G" = ":select -1<Enter>";
          "J" = ":next-folder<Enter>";
          "K" = ":prev-folder<Enter>";
          "<Space>" = ":mark -t<Enter>:next<Enter>";
          "<Tab>" = ":exec checkmail<Enter>";
          "<Enter>" = ":view<Enter>";
          "d" = ":choose -o y 'Really delete this message' delete-message<Enter>";
          "D" = ":delete-message<Enter>";
          "a" = ":read<Enter>:archive flat<Enter>";
          "A" = ":unmark -a<Enter>:mark -T<Enter>:read<Enter>:mark -T<Enter>:archive flat<Enter>";
          "s" = ":read<Enter>:move Junk<Enter>";
          "m" = ":compose<Enter>";
          "r" = ":reply -aq<Enter>";
          "$" = ":term<space>";
          "!" = ":term<space>";
          "|" = ":pipe<space>";
          "/" = ":search<space>";
          "\\" = ":change-tab notmuch<Enter>:cf<Space>";
          "+" =
            '':query -n "{{.SubjectBase}} ({{.MessageId}})" -a notmuch thread:\{id:{{.MessageId}}\}<Enter>'';
          "n" = ":next-result<Enter>";
          "N" = ":prev-result<Enter>";
          "<Esc>" = ":clear<Enter>";
          "v" = ":split<Enter>";
          "V" = ":vsplit<Enter>";
        };

        "messages:folder=Drafts" = {
          "<Enter>" = ":recall<Enter>";
        };

        view = {
          "/" = ":toggle-key-passthrough<Enter>/";
          "q" = ":close<Enter>";
          "o" = ":open<Enter>";
          "S" = ":save<space>";
          "|" = ":pipe<space>";
          "a" = ":archive flat<Enter>";
          "s" = ":move Junk<Enter>";
          "<C-l>" = ":open-link<space>";
          "f" = ":forward<Enter>";
          "r" = ":reply -aq<Enter>";
          "H" = ":toggle-headers<Enter>";
          "<C-p>" = ":prev-part<Enter>";
          "<C-n>" = ":next-part<Enter>";
          "J" = ":next<Enter>";
          "K" = ":prev<Enter>";
        };

        "view::passthrough" = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "<Esc>" = ":toggle-key-passthrough<Enter>";
        };

        compose = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
        };

        "compose::editor" = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
        };

        # string form to preserve comments
        "compose::review" = ''
          y = :send<Enter> # Send
          n = :abort<Enter> # Abort (discard message, no confirmation)
          v = :preview<Enter> # Preview message
          p = :postpone<Enter> # Postpone
          q = :choose -o d discard abort -o p postpone postpone<Enter> # Abort or postpone
          e = :edit<Enter> # Edit
          a = :menu -c 'fd . --type=f | fzf -m' attach<Enter> # Add attachment
          d = :detach<space> # Remove attachment
          s = :sign<Enter> # PGP sign
        '';

        terminal = {
          "$noinherit" = "true";
          "$ex" = "<C-x>";
          "<C-p>" = ":prev-tab<Enter>";
          "<C-n>" = ":next-tab<Enter>";
        };
      };
    };

    notmuch = {
      enable = false;
      new = {
        ignore = [
          ".uidvalidity"
          ".mbsyncstate"
          ".mbsyncstate.lock"
          ".mbsyncstate.journal"
          ".mbsyncstate.new"
        ];
        tags = [
          "unread"
          "inbox"
          "new"
        ];
      };
    };

    msmtp.enable = true;
    mbsync.enable = true;
  };

  services = {
    imapnotify.enable = true;
  };

  home.packages = with pkgs; [
    aerc
    w3m
  ];
}
