{ pkgs, perSystem, ... }:
let
  scripts = perSystem.self.qutebrowser-scripts;
in
{
  programs.qutebrowser = {
    enable = true;
    package = pkgs.qutebrowser;

    searchEngines = {
      DEFAULT = "https://kagi.com/search?q={}";
      np = "https://search.nixos.org/packages?channel=unstable&query={}";
      no = "https://search.nixos.org/options?channel=unstable&query={}";
      nw = "https://wiki.nixos.org/w/index.php?search={}";
      gh = "https://github.com/search?q={}";
    };

    settings = {
      tabs = {
        position = "left";
        width = 250;
        show = "multiple";
        title.format = "{audio}{index}: {current_title}";
        last_close = "close";
        new_position.related = "next";
        favicons.show = "always";
      };

      colors = {
        webpage = {
          darkmode.enabled = true;
          preferred_color_scheme = "dark";
        };
      };

      content = {
        blocking = {
          enabled = true;
          method = "both";
          adblock.lists = [
            "https://easylist.to/easylist/easylist.txt"
            "https://easylist.to/easylist/easyprivacy.txt"
            "https://easylist-downloads.adblockplus.org/antiadblockfilters.txt"
            "https://secure.fanboy.co.nz/fanboy-annoyance.txt"
          ];
        };

        canvas_reading = true;
        webgl = true;
        headers = {
          accept_language = "en-US,en;q=0.5";
        };
        javascript.clipboard = "access";

        autoplay = false;
      };

      completion.shrink = true;
      url = {
        default_page = "https://kagi.com";
        start_pages = [ "https://kagi.com" ];
      };

      scrolling = {
        bar = "always";
        smooth = true;
      };

      statusbar.position = "top";
      downloads.position = "bottom";

      hints.chars = "asdfghjkl";

      editor.command = [
        "footclient"
        "-e"
        "nvim"
        "{file}"
      ];

      auto_save.session = true;
      session.lazy_restore = true;
    };

    keyBindings = {
      normal = {
        ",t" = "config-cycle tabs.show always never";

        "j" = "scroll down";
        "k" = "scroll up";
        "h" = "scroll left";
        "l" = "scroll right";
        "gg" = "scroll-to-perc 0";
        "G" = "scroll-to-perc 100";
        "d" = "cmd-run-with-count 15 scroll down";
        "u" = "cmd-run-with-count 15 scroll up";
        "zH" = "scroll-to-perc --horizontal 0";
        "zL" = "scroll-to-perc --horizontal 100";

        "J" = "tab-next";
        "K" = "tab-prev";
        "g0" = "tab-focus 1";
        "g$" = "tab-focus -1";
        "t" = "open -t";
        "x" = "tab-close";
        "X" = "undo";
        "yt" = "tab-clone";
        "W" = "tab-give";
        "<<" = "tab-move -";
        ">>" = "tab-move +";
        "<Ctrl-Tab>" = "tab-focus stack-prev";
        "<Ctrl-Shift-Tab>" = "tab-focus stack-next";
        "<Alt-p>" = "tab-pin";
        "<Alt-m>" = "tab-mute";

        "f" = "hint";
        "F" = "hint all tab";
        "<Alt-f>" = "hint all tab-bg";
        "o" = "spawn --userscript ${scripts}/bin/qute-vomnibar open";
        "O" = "spawn --userscript ${scripts}/bin/qute-vomnibar tab";
        "b" = "set-cmd-text -s :bookmark-load";
        "B" = "set-cmd-text -s :bookmark-load -t";
        "T" = "set-cmd-text -s :tab-select";
        "ge" = "set-cmd-text :open {url}";
        "gE" = "set-cmd-text :open -t {url}";
        "gu" = "navigate up";
        "gU" = "navigate up -t";
        "yf" = "hint links yank";
        "yy" = "yank";
        "yi" = "hint images yank";
        "P" = "open -- {clipboard}";
        "p" = "open -t -- {clipboard}";

        "/" = "set-cmd-text /";
        "n" = "search-next";
        "N" = "search-prev";

        "H" = "back";
        "L" = "forward";

        "gs" = "view-source";
        "gi" = "hint inputs";

        "]]" = "navigate next";
        "[[" = "navigate prev";

        "M" = "hint links spawn --detach mpv {hint-url}";
        ",m" = "spawn --detach mpv {url}";

        ",p" = "spawn --userscript ${scripts}/bin/qute-1pass";

        "r" = "reload";
        "R" = "reload -f";
      };

      insert = {
        "<Ctrl-[>" = "mode-leave";
      };
    };

    extraConfig = ''
      c.spellcheck.languages = ["en-US"]

      import os
      profile = os.environ.get("QUTE_PROFILE", "")
      profile_colors = {
          "personal": {"accent": "#37adff", "accent_fg": "#ffffff"},
          "work":     {"accent": "#c47a2d", "accent_fg": "#ffffff"},
      }
      if profile in profile_colors:
          pc = profile_colors[profile]
          c.colors.statusbar.normal.bg = pc["accent"]
          c.colors.statusbar.normal.fg = pc["accent_fg"]
          c.colors.statusbar.url.fg = pc["accent_fg"]
          c.colors.statusbar.url.hover.fg = pc["accent_fg"]
          c.colors.statusbar.url.success.http.fg = pc["accent_fg"]
          c.colors.statusbar.url.success.https.fg = pc["accent_fg"]
          c.colors.tabs.selected.even.bg = pc["accent"]
          c.colors.tabs.selected.even.fg = pc["accent_fg"]
          c.colors.tabs.selected.odd.bg = pc["accent"]
          c.colors.tabs.selected.odd.fg = pc["accent_fg"]
          c.window.title_format = "{perc}{current_title}{title_sep}qutebrowser [{profile}]".replace("{profile}", profile)
    '';
  };

  home.packages = [ scripts ];

  xdg.desktopEntries = {
    "qutebrowser-personal" = {
      name = "Qutebrowser (Personal)";
      exec = "${scripts}/bin/qute-profile launch personal %u";
      terminal = false;
      type = "Application";
      icon = "qutebrowser";
      categories = [
        "Network"
        "WebBrowser"
      ];
    };
    "qutebrowser-work" = {
      name = "Qutebrowser (Work)";
      exec = "${scripts}/bin/qute-profile launch work %u";
      terminal = false;
      type = "Application";
      icon = "qutebrowser";
      categories = [
        "Network"
        "WebBrowser"
      ];
    };
    "qutebrowser-open" = {
      name = "Qutebrowser";
      exec = "${scripts}/bin/qute-open %u";
      terminal = false;
      type = "Application";
      icon = "qutebrowser";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "text/html"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    };
  };
}
