{ lib, pkgs, ... }:
let
  exportToObsidian = pkgs.writeShellScriptBin "claude-export-to-obsidian" ''
    set -euo pipefail

    VAULT_PATH="$HOME/obsidian/ai-conversations/claude-code"
    CLAUDE_PROJECTS="$HOME/.claude/projects"

    mkdir -p "$VAULT_PATH"

    PROJECT_PATH=$(pwd | sed 's|/|-|g')
    PROJECT_DIR="$CLAUDE_PROJECTS/$PROJECT_PATH"

    if [ ! -d "$PROJECT_DIR" ]; then
      exit 0
    fi

    LATEST_CONV=$(ls -t "$PROJECT_DIR"/*.jsonl 2>/dev/null | head -n 1)

    if [ -z "$LATEST_CONV" ] || [ ! -f "$LATEST_CONV" ]; then
      exit 0
    fi

    PROJECT_NAME=$(basename "$PWD")
    DATE=$(date +%Y-%m-%d)
    CONV_ID=$(basename "$LATEST_CONV" .jsonl | cut -c1-8)

    EXISTING=$(find "$VAULT_PATH" -maxdepth 1 -name "*-$CONV_ID.md" 2>/dev/null | head -n 1)
    if [ -n "$EXISTING" ]; then
      OUTPUT_FILE="$EXISTING"
    else
      OUTPUT_FILE="$VAULT_PATH/$DATE-$PROJECT_NAME-$CONV_ID.md"
    fi

    {
      echo "---"
      echo "type: ai-conversation"
      echo "source: claude-code"
      echo "project: $PROJECT_NAME"
      echo "date: $DATE"
      echo "conversation_id: $CONV_ID"
      echo "tags:"
      echo "  - ai-conversation"
      echo "  - claude-code"
      echo "---"
      echo ""
      echo "# Claude Code Conversation"
      echo ""
      echo "**Project:** $PROJECT_NAME"
      echo "**Date:** $DATE"
      echo ""
      echo "---"
      echo ""

      ${lib.getExe pkgs.jq} -r '
        select(.type == "user" or .type == "assistant") |
        (
          if .message.content | type == "array" then
            [.message.content[] | select(.type == "text") | .text] | join("\n")
          else
            .message.content // ""
          end
        ) as $text |
        if ($text | length) > 0 then
          "## " + (.type | ascii_upcase | .[0:1]) + (.type | .[1:]) + "\n\n" + $text + "\n"
        else empty end
      ' "$LATEST_CONV"
    } > "$OUTPUT_FILE"
  '';
in
{
  home.packages = [ exportToObsidian ];

  programs.claude-code = {
    enable = true;
    settings = {
      hooks = {
        Stop = [
          {
            hooks = [
              {
                type = "command";
                command = "${lib.getExe pkgs.libnotify} 'Claude Code' 'I am done!' -i cog";
              }
              {
                type = "command";
                command = "${lib.getExe exportToObsidian}";
              }
            ];
          }
        ];
        Notification = [
          {
            hooks = [
              {
                type = "command";
                command = "${lib.getExe pkgs.libnotify} 'Claude Code' 'I need your help!' -i cog";
              }
            ];
          }
        ];
      };
    };
  };
}
