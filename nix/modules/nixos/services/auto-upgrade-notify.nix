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

    WARNINGS=$(${pkgs.systemd}/bin/journalctl -u ${cfg.upgradeServiceName} -n ${toString cfg.logLines} --no-pager | ${pkgs.gnugrep}/bin/grep -i "warning" || echo "No warnings")
    ERRORS=$(${pkgs.systemd}/bin/journalctl -u ${cfg.upgradeServiceName} -n ${toString cfg.logLines} --no-pager | ${pkgs.gnugrep}/bin/grep -i "error" || echo "No errors")

    WARNINGS_HTML=$(echo "$WARNINGS" | ${pkgs.gnused}/bin/sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g' | ${pkgs.gnused}/bin/sed ':a;N;$!ba;s/\n/<br>/g')
    ERRORS_HTML=$(echo "$ERRORS" | ${pkgs.gnused}/bin/sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g' | ${pkgs.gnused}/bin/sed ':a;N;$!ba;s/\n/<br>/g')

    HTML_BODY=$(cat <<HTML
    <html>
    <body style='font-family: monospace; max-width: 1200px; margin: 20px;'>
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

      <h3 style='color: #ff8800;'>⚠️ Warnings</h3>
      <div style='background-color: #fff8e1; padding: 15px; border-left: 4px solid #ff8800; margin: 10px 0;'>
        <pre style='margin: 0; white-space: pre-wrap; word-wrap: break-word;'>$WARNINGS_HTML</pre>
      </div>

      <h3 style='color: #d32f2f;'>❌ Errors</h3>
      <div style='background-color: #ffebee; padding: 15px; border-left: 4px solid #d32f2f; margin: 10px 0;'>
        <pre style='margin: 0; white-space: pre-wrap; word-wrap: break-word;'>$ERRORS_HTML</pre>
      </div>
    </body>
    </html>
    HTML
    )

    ${pkgs.jq}/bin/jq -n \
      --arg from "${cfg.fromEmail}" \
      --arg to ${builtins.toJSON cfg.toEmails} \
      --arg subject "$STATUS_EMOJI ${cfg.emailSubjectPrefix} $STATUS_TEXT: $HOSTNAME" \
      --arg html "$HTML_BODY" \
      '{from: $from, to: $to, subject: $subject, html: $html}' | \
    ${pkgs.curl}/bin/curl -X POST https://api.resend.com/emails \
      -H "Authorization: Bearer $RESEND_API_KEY" \
      -H "Content-Type: application/json" \
      -d @-
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
