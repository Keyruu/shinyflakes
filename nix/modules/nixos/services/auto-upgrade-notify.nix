{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.autoUpgradeNotify;

  notificationScript = pkgs.writeShellScript "upgrade-notify" ''
    set -euo pipefail

    STATUS=$1
    STATE_FILE="/var/lib/nixos-upgrade-notify/last-generation"

    RESEND_API_KEY=$(cat ${cfg.resendApiKeyPath})
    HOSTNAME=$(${pkgs.nettools}/bin/hostname)
    GENERATION=$(${pkgs.coreutils}/bin/readlink -f /run/current-system || echo "unknown")
    TIMESTAMP=$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S %Z')

    if [ "$STATUS" = "success" ]; then
      STATUS_EMOJI="✅"
      STATUS_TEXT="Success"

      if [ -f "$STATE_FILE" ]; then
        LAST_GENERATION=$(${pkgs.coreutils}/bin/cat "$STATE_FILE")
        if [ "$GENERATION" = "$LAST_GENERATION" ]; then
          echo "No changes detected, skipping notification"
          exit 0
        fi
      fi
    else
      STATUS_EMOJI="❌"
      STATUS_TEXT="Failed"
    fi

    START_TIME=$(${pkgs.systemd}/bin/systemctl show -p InactiveExitTimestamp ${cfg.upgradeServiceName} --value)
    WARNINGS=$(${pkgs.systemd}/bin/journalctl -u ${cfg.upgradeServiceName} --since "$START_TIME" --no-pager | ${pkgs.gnugrep}/bin/grep -i "warning" || echo "No warnings")
    ERRORS=$(${pkgs.systemd}/bin/journalctl -u ${cfg.upgradeServiceName} --since "$START_TIME" --no-pager | ${pkgs.gnugrep}/bin/grep -i "error" || echo "No errors")
    ALL_LOGS=$(${pkgs.systemd}/bin/journalctl -u ${cfg.upgradeServiceName} --since "$START_TIME" --no-pager || echo "No logs available")

    TEXT_BODY=$(cat <<TEXT
    $STATUS_EMOJI ${cfg.emailSubjectPrefix} $STATUS_TEXT

    Hostname:   $HOSTNAME
    Status:     $STATUS_TEXT
    Timestamp:  $TIMESTAMP
    Generation: $GENERATION

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ⚠️  WARNINGS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    $WARNINGS

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ❌ ERRORS
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    $ERRORS

    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    📋 FULL LOGS (from last invocation)
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    $ALL_LOGS
    TEXT
    )

    TO_EMAILS='${builtins.toJSON cfg.toEmails}'

    ${pkgs.jq}/bin/jq -n \
      --arg from "${cfg.fromEmail}" \
      --argjson to "$TO_EMAILS" \
      --arg subject "$STATUS_EMOJI ${cfg.emailSubjectPrefix} $STATUS_TEXT: $HOSTNAME" \
      --arg text "$TEXT_BODY" \
      '{from: $from, to: $to, subject: $subject, text: $text}' | \
    ${pkgs.curl}/bin/curl -X POST https://api.resend.com/emails \
      -H "Authorization: Bearer $RESEND_API_KEY" \
      -H "Content-Type: application/json" \
      -d @-

    if [ "$STATUS" = "success" ]; then
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$STATE_FILE")"
      echo "$GENERATION" > "$STATE_FILE"
      echo "Saved generation to state file"
    fi
  '';
in
{
  options.services.autoUpgradeNotify = {
    enable = lib.mkEnableOption "automatic NixOS upgrades with email notifications";

    # Auto-upgrade options
    flake = lib.mkOption {
      type = lib.types.str;
      example = "github:user/repo";
      description = "The flake URL to upgrade from";
    };

    dates = lib.mkOption {
      type = lib.types.str;
      default = "04:40";
      example = "daily";
      description = "When to run the upgrade (systemd timer format)";
    };

    operation = lib.mkOption {
      type = lib.types.enum [
        "switch"
        "boot"
      ];
      default = "switch";
      description = "Whether to switch immediately or boot into the new generation";
    };

    allowReboot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to reboot if kernel/initrd changed";
    };

    randomizedDelaySec = lib.mkOption {
      type = lib.types.str;
      default = "0";
      example = "45min";
      description = "Add randomized delay before upgrade";
    };

    upgradeServiceName = lib.mkOption {
      type = lib.types.str;
      default = "nixos-upgrade";
      description = "The systemd service name to monitor and attach notifications to";
    };

    resendApiKeyPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to the Resend API key file";
    };

    fromEmail = lib.mkOption {
      type = lib.types.str;
      example = "nixos-upgrade@example.com";
      description = "The sender email address";
    };

    toEmails = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      example = [ "admin@example.com" ];
      description = "List of recipient email addresses";
    };

    emailSubjectPrefix = lib.mkOption {
      type = lib.types.str;
      default = "NixOS Upgrade";
      description = "Prefix for email subject lines";
    };
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      inherit (cfg)
        flake
        dates
        operation
        allowReboot
        randomizedDelaySec
        ;
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/nixos-upgrade-notify 0755 root root"
    ];

    systemd.services."${cfg.upgradeServiceName}-notify-success" = {
      description = "Notify on successful system upgrade";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${notificationScript} success";
      };
    };

    systemd.services."${cfg.upgradeServiceName}-notify-failure" = {
      description = "Notify on failed system upgrade";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${notificationScript} failure";
      };
    };

    systemd.services.${cfg.upgradeServiceName} = {
      unitConfig = {
        OnSuccess = "${cfg.upgradeServiceName}-notify-success.service";
        OnFailure = "${cfg.upgradeServiceName}-notify-failure.service";
      };
      serviceConfig = {
        # Prevent concurrent runs
        Type = "oneshot";
      };
    };

    systemd.timers.${lib.replaceStrings [ ".service" ] [ ".timer" ] cfg.upgradeServiceName} = {
      timerConfig = {
        # Skip if previous run is still active
        Unit = cfg.upgradeServiceName;
      };
    };
  };
}
