{ ... }:
{
  den.aspects.browsers.browser-picker = {
    homeManager =
      { lib, pkgs, ... }:
      let
        # Hosts matched against the url host, per profile. Bash case patterns
        # need the literal dot, so *.foo.com does not cover the apex host.
        routes = {
          work = [
            "slack.com"
            "*.slack.com"
            "mail.google.de"
            "calendar.google.de"
            "meet.google.de"
            "docs.google.de"
            "docs.google.com"
            "console.cloud.google.com"
            "linear.app"
            "github.com"
            "dash0.com"
            "*.dash0.com"
            "*.aws.amazon.com"
            "*.awsapps.com"
          ];
          default = [ "*.peeraten.net" ];
        };

        # Built here, not inline in the script body: a nested ${...} there is
        # parsed by the outer indented string (eval fails: undefined 'r').
        # Attrsets are sorted, so a host listed under two profiles resolves to
        # the alphabetically first one — keep the lists disjoint.
        caseBody = lib.concatStrings (
          lib.mapAttrsToList (
            profile: hosts:
              "  ${lib.concatStringsSep "|" hosts}) profile=${lib.escapeShellArg profile} ;;\n"
          ) routes
        );

        # Direct launchers so the profiles are reachable without a prompt.
        profileNames = [
          "default"
          "work"
        ];

        # firefox only, everything else (vicinae) comes from the ambient PATH:
        # writeShellApplication prepends runtimeInputs instead of replacing PATH.
        browserPicker = pkgs.writeShellApplication {
          name = "browser-picker";
          runtimeInputs = [ pkgs.firefox ];
          text = # bash
            ''
              profiles_ini="''${FIREFOX_PROFILES_INI:-$HOME/.mozilla/firefox/profiles.ini}"
              url="''${1:-}"

              if [[ ! -f "$profiles_ini" ]]; then
                echo "browser-picker: no profiles.ini at $profiles_ini" >&2
                exit 1
              fi

              profiles=( )
              while IFS= read -r line; do
                [[ "$line" == Name=* ]] && profiles+=( "''${line#Name=}" )
              done <"$profiles_ini"

              if [[ ''${#profiles[@]} -eq 0 ]]; then
                echo "browser-picker: no Name= entries in $profiles_ini" >&2
                exit 1
              fi

              host=""
              if [[ -n "$url" ]]; then
                host="''${url#*://}"
                host="''${host%%[/?#]*}"
                host="''${host##*@}"
                host="''${host%%:*}"
              fi

              profile=""
              case "$host" in
              ${caseBody}
              esac

              if [[ -z "$profile" ]]; then
                # Pipe must not start a line here: inside $( ) bash rejects a
                # leading |, so the continuation goes on the printf line.
                profile=$(printf '%s\n' "''${profiles[@]}" \
                  | vicinae dmenu -f data -p "Profile for ''${host:-new window}") || exit 0
              fi

              # No --no-remote: the running instance of that profile gets the url
              # as a new tab instead of a fresh window/process.
              if [[ -n "$url" ]]; then
                exec firefox -P "$profile" "$url"
              else
                exec firefox -P "$profile"
              fi
            '';
        };
      in
      {
        home.packages = [ browserPicker ];

        xdg.desktopEntries = lib.listToAttrs (
          map (profile: {
            name = "firefox-${profile}";
            value = {
              name = "Firefox (${profile})";
              genericName = "Web Browser";
              exec = "${lib.getExe pkgs.firefox} -P ${profile}";
              icon = "firefox";
              categories = [
                "Network"
                "WebBrowser"
              ];
            };
          }) profileNames
        ) // {
          browser-picker = {
            name = "Browser (pick profile)";
            genericName = "Web Browser";
            comment = "Open links in a firefox profile of your choice";
            exec = "${lib.getExe browserPicker} %u";
            icon = "firefox";
            categories = [
              "Network"
              "WebBrowser"
            ];
            mimeType = [
              "text/html"
              "text/xhtml"
              "x-scheme-handler/http"
              "x-scheme-handler/https"
            ];
            terminal = false;
          };
        };
      };
  };
}
