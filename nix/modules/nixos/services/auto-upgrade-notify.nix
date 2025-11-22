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

    RESEND_API_KEY=$(cat ${cfg.resendApiKeyPath})
    HOSTNAME=$(${pkgs.nettools}/bin/hostname)
    GENERATION=$(${pkgs.coreutils}/bin/readlink -f /run/current-system || echo "unknown")
    TIMESTAMP=$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S %Z')

    if [ "$STATUS" = "success" ]; then
      STATUS_EMOJI="✅"
      STATUS_TEXT="Success"
      STATUS_COLOR="green"
    else
      STATUS_EMOJI="❌"
      STATUS_TEXT="Failed"
      STATUS_COLOR="red"
    fi

    LOGS=$(${pkgs.systemd}/bin/journalctl -u ${cfg.upgradeServiceName} -n ${toString cfg.logLines} --no-pager || echo "Could not fetch logs")
    WARNINGS=$(echo "$LOGS" | ${pkgs.gnugrep}/bin/grep -i "warning" || echo "No warnings found")
    ERRORS=$(echo "$LOGS" | ${pkgs.gnugrep}/bin/grep -i "error" || echo "No errors found")

    LOGS_ESCAPED=$(echo "$LOGS" | ${pkgs.gnused}/bin/sed 's/"/\\"/g' | ${pkgs.gnused}/bin/sed ':a;N;$!ba;s/\n/<br>/g')
    WARNINGS_ESCAPED=$(echo "$WARNINGS" | ${pkgs.gnused}/bin/sed 's/"/\\"/g' | ${pkgs.gnused}/bin/sed ':a;N;$!ba;s/\n/<br>/g')
    ERRORS_ESCAPED=$(echo "$ERRORS" | ${pkgs.gnused}/bin/sed 's/"/\\"/g' | ${pkgs.gnused}/bin/sed ':a;N;$!ba;s/\n/<br>/g')

    RESEND_BODY=$(cat <<EOF
    {
      "from": "${cfg.fromEmail}",
      "to": ${builtins.toJSON cfg.toEmails},
      "subject": "$STATUS_EMOJI ${cfg.emailSubjectPrefix} $STATUS_TEXT: $HOSTNAME",
      "html": "<html><body style='font-family: monospace; max-width: 1200px; margin: 20px;'>
        <h2 style='color: $STATUS_COLOR;'>$STATUS_EMOJI ${cfg.emailSubjectPrefix} $STATUS_TEXT</h2>
        <table style='border-collapse: collapse; margin: 20px 0;'>
          <tr style='background-color: #f5f5f5;'>
            <td style='padding: 12px; font-weight: bold; border: 1px solid #ddd;'>Hostname</td>
            <td style='padding: 12px; border: 1px solid #ddd;'>$HOSTNAME</td>
          </tr>
          <tr>
            <td style='padding: 12px; font-weight: bold; border: 1px solid #ddd;'>Status</td>
            <td style='padding: 12px; border: 1px solid #ddd; color: $STATUS_COLOR;'>$STATUS_TEXT</td>
          </tr>
          <tr style='background-color: #f5f5f5;'>
            <td style='padding: 12px; font-weight: bold; border: 1px solid #ddd;'>Timestamp</td>
            <td style='padding: 12px; border: 1px solid #ddd;'>$TIMESTAMP</td>
          </tr>
          <tr>
            <td style='padding: 12px; font-weight: bold; border: 1px solid #ddd;'>Generation</td>
            <td style='padding: 12px; border: 1px solid #ddd;'><code>$GENERATION</code></td>
          </tr>
        </table>

        <h3 style='color: #ff8800; margin-top: 30px;'>⚠️ Warnings</h3>
        <div style='background-color: #fff8e1; padding: 15px; border-left: 4px solid #ff8800; margin: 10px 0; max-height: 300px; overflow-y: auto;'>
          <pre style='margin: 0; white-space: pre-wrap; word-wrap: break-word;'>$WARNINGS_ESCAPED</pre>
        </div>

        <h3 style='color: #d32f2f; margin-top: 30px;'>❌ Errors</h3>
        <div style='background-color: #ffebee; padding: 15px; border-left: 4px solid #d32f2f; margin: 10px 0; max-height: 300px; overflow-y: auto;'>
          <pre style='margin: 0; white-space: pre-wrap; word-wrap: break-word;'>$ERRORS_ESCAPED</pre>
        </div>

        <details style='margin-top: 30px;'>
          <summary style='cursor: pointer; font-weight: bold; padding: 10px; background-color: #f5f5f5; border: 1px solid #ddd;'>
            📋 Full Logs (last ${toString cfg.logLines} lines)
          </summary>
          <div style='background-color: #f9f9f9; padding: 15px; border: 1px solid #ddd; margin-top: 5px; max-height: 500px; overflow-y: auto;'>
            <pre style='margin: 0; white-space: pre-wrap; word-wrap: break-word; font-size: 12px;'>$LOGS_ESCAPED</pre>
          </div>
        </details>
      </body></html>"
    }
    EOF
    )

    ${pkgs.curl}/bin/curl -X POST https://api.resend.com/emails \
      -H "Authorization: Bearer $RESEND_API_KEY" \
      -H "Content-Type: application/json" \
      -d "$RESEND_BODY"
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
      default = "nixos-upgrade.service";
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

    logLines = lib.mkOption {
      type = lib.types.int;
      default = 100;
      description = "Number of log lines to include in the notification";
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
    };
  };
}
