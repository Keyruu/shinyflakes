{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.sudo-notify;

  # pam_exec runs as root; bounce into the calling user's session bus so the
  # notification actually reaches their desktop.
  script = pkgs.writeShellScript "sudo-notify" ''
    set -u
    user="''${PAM_RUSER:-}"
    [ -z "$user" ] && exit 0
    [ "$user" = "root" ] && exit 0

    uid="$(${pkgs.coreutils}/bin/id -u "$user" 2>/dev/null)" || exit 0
    runtime="/run/user/$uid"
    [ -S "$runtime/bus" ] || exit 0

    ${pkgs.util-linux}/bin/runuser -u "$user" -- \
      ${pkgs.coreutils}/bin/env \
        XDG_RUNTIME_DIR="$runtime" \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus" \
      ${lib.getExe pkgs.libnotify} \
        -u critical \
        -i dialog-password \
        -a sudo \
        -t 10000 \
        "sudo" "Password requested on ''${PAM_TTY:-?}" &
    exit 0
  '';

  rule = {
    control = "optional";
    modulePath = "${pkgs.linux-pam}/lib/security/pam_exec.so";
    args = [
      "quiet"
      "${script}"
    ];
    # before fprintd (11400) and pam_unix (11700) so notification fires
    # before the password prompt blocks the terminal
    order = 10500;
  };
in
{
  options.services.sudo-notify.enable = lib.mkEnableOption "desktop notification when sudo prompts for a password";

  config = lib.mkIf cfg.enable {
    security.pam.services.sudo.rules.auth.notify = rule;
    security.pam.services.sudo-i.rules.auth.notify = rule;
  };
}
