{ pkgs, ... }:
let
  niri-workstyle =
    pkgs.writeShellScriptBin "niri-workstyle" # bash
      ''
        set -euo pipefail

        CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}"
        WORKSTYLE_CONFIG="$CONFIG_DIR/niri/workstyle.toml"

        FOCUSED_FORMAT=""
        if [[ -f "$WORKSTYLE_CONFIG" ]]; then
            FOCUSED_FORMAT=$(tomlq -r ".focused_format // empty" "$WORKSTYLE_CONFIG")
        fi

        get_icon_for_app() {
            local app_id="$1"
            local default_icon="*"

            if [[ ! -f "$WORKSTYLE_CONFIG" ]]; then
                echo "$default_icon"
                return
            fi

            local icon=$(tomlq -r ".matches.\"$app_id\" // empty" "$WORKSTYLE_CONFIG")

            if [[ -n "$icon" && "$icon" != "null" ]]; then
                echo "$icon"
            else
                default_icon=$(tomlq -r ".default // \"*\"" "$WORKSTYLE_CONFIG")
                echo "$default_icon"
            fi
        }

        format_icons() {
            local icons="$1"

            if [[ -z "$FOCUSED_FORMAT" || "$FOCUSED_FORMAT" == "null" ]]; then
                echo "$icons"
                return
            fi

            echo "''${FOCUSED_FORMAT//\{\}/$icons}"
        }

        get_workspace_icons() {
            local workspace_id="$1"

            local windows_json=$(niri msg --json windows | jq -c "[.[] | select(.workspace_id == $workspace_id)] | sort_by(.is_floating, .layout.pos_in_scrolling_layout[0] // 999) | .[] | {app_id, is_focused}")

            local icons=""
            while IFS= read -r window; do
                if [[ -n "$window" ]]; then
                    local app_id=$(echo "$window" | jq -r '.app_id')
                    local is_focused=$(echo "$window" | jq -r '.is_focused')
                    local icon=$(get_icon_for_app "$app_id")

                    if [[ "$is_focused" == "true" ]]; then
                        icon=$(format_icons "$icon")
                    fi

                    icons+="$icon "
                fi
            done <<< "$windows_json"

            echo "''${icons% }"
        }

        current_workspace_id=""

        niri msg --json event-stream | while IFS= read -r line; do
            event_type=$(echo "$line" | jq -r 'keys[0]')

            case "$event_type" in
                "WorkspaceActivated")
                    workspace_id=$(echo "$line" | jq -r '.WorkspaceActivated.id')

                    if [[ -n "$workspace_id" ]]; then
                        current_workspace_id="$workspace_id"
                    fi
                    ;;

                "WorkspacesChanged")
                    workspace_id=$(echo "$line" | jq -r '.WorkspacesChanged.workspaces[] | select(.is_focused == true) | .id')

                    if [[ -n "$workspace_id" ]]; then
                        current_workspace_id="$workspace_id"
                    fi
                    ;;

                "WindowFocusChanged")
                    # Get the workspace of the focused window
                    focused_workspace_id=$(niri msg --json windows | jq -r '.[] | select(.is_focused == true) | .workspace_id')

                    if [[ -n "$focused_workspace_id" ]]; then
                        current_workspace_id="$focused_workspace_id"
                        icons=$(get_workspace_icons "$focused_workspace_id")

                        echo "$icons"
                    fi
                    ;;
            esac
        done
      '';

in
{
  home.packages = [
    niri-workstyle
  ];

  home.file.".config/sworkstyle/config.toml".text = # toml
    ''
      [matching]
      # Browsers
      'zen' = '󰰷'

      # Terminals
      'org.wezfurlong.wezterm' = ''

      'discord' = ''
      'Discord' = ''
      'Webcord' = ''
      'webcord' = ''
      'vesktop' = ' '
      'VSCode' = '󰨞'
      'code-url-handler' = '󰨞'
      'code-oss' = '󰨞'
      'codium' = '󰨞'
      'codium-url-handler' = '󰨞'
      'VSCodium' = '󰨞'
      'Code' = '󰨞'
      'dev.zed.Zed' = '󰬡'
      'signal' = '󰭹'

      'spotify_player' = ''
      'spotify' = ''
      '1Password' = ''
      'Element' = '󰭹'
    '';

  home.file.".config/niri/workstyle.toml".text = # toml
    ''
      default = "*"
      focused_format = "<span foreground='#89b4fa'><big>{}</big></span>"

      [matches]
      # Browsers
      'zen' = '󰰷'

      # Terminals
      'org.wezfurlong.wezterm' = ''

      'discord' = '󰙯'
      'Discord' = '󰙯'
      'Webcord' = '󰙯'
      'webcord' = '󰙯'
      'vesktop' = '󰙯'
      'VSCode' = '󰨞'
      'code-url-handler' = '󰨞'
      'code-oss' = '󰨞'
      'codium' = '󰨞'
      'codium-url-handler' = '󰨞'
      'VSCodium' = '󰨞'
      'Code' = '󰨞'
      'dev.zed.Zed' = '󰬡'
      'signal' = '󰭹'

      'spotify_player' = ''
      'spotify' = ''
      '1Password' = ''
      'Element' = '󰭹'
    '';
}
