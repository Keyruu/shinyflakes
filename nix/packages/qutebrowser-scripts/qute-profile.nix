{ pkgs }:
pkgs.writeShellApplication {
  name = "qute-profile";
  runtimeInputs = with pkgs; [ vicinae qutebrowser ];
  excludeShellChecks = [ "SC2012" ];
  text = ''
    PROFILES_DIR="''${XDG_DATA_HOME:-$HOME/.local/share}/qutebrowser-profiles"
    CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/qutebrowser"

    usage() {
      echo "Usage: qute-profile [launch <name>|choose|list|new <name>]"
      echo ""
      echo "  launch <name>  Launch a profile (creates if needed)"
      echo "  choose         Pick a profile via vicinae"
      echo "  list           List existing profiles"
      echo "  new <name>     Create a profile without launching"
      exit 1
    }

    ensure_profile() {
      local name="$1"
      local basedir="$PROFILES_DIR/$name"

      if [ ! -d "$basedir/config" ]; then
        mkdir -p "$basedir/config" "$basedir/data" "$basedir/cache"
        ln -sf "$CONFIG_DIR/config.py" "$basedir/config/config.py"
      fi

      echo "$basedir"
    }

    launch() {
      local name="$1"; shift
      local basedir
      basedir=$(ensure_profile "$name")
      export QUTE_PROFILE="$name"
      exec qutebrowser --basedir "$basedir" --desktop-file-name "qutebrowser-$name" "$@"
    }

    case "''${1:-}" in
      launch)
        [ -z "''${2:-}" ] && usage
        shift; launch "$@"
        ;;
      choose)
        shift
        if [ ! -d "$PROFILES_DIR" ] || [ -z "$(ls -A "$PROFILES_DIR" 2>/dev/null)" ]; then
          echo "No profiles found. Create one with: qute-profile new <name>" >&2
          exit 1
        fi
        SELECTED=$(ls -1 "$PROFILES_DIR" | vicinae dmenu -p "qutebrowser profile:")
        [ -z "$SELECTED" ] && exit 0
        launch "$SELECTED" "$@"
        ;;
      list)
        if [ -d "$PROFILES_DIR" ]; then
          ls -1 "$PROFILES_DIR" 2>/dev/null
        fi
        ;;
      new)
        [ -z "''${2:-}" ] && usage
        ensure_profile "$2" >/dev/null
        echo "Created profile: $2"
        ;;
      *)
        usage
        ;;
    esac
  '';
}
