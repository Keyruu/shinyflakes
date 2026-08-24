{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "shiny-install";
  runtimeInputs = with pkgs; [
    coreutils
    findutils
    gnugrep
    gum
    systemd
    util-linux
  ];
  text = ''
    if [ -t 1 ] && [ -z "''${NO_COLOR:-}" ] && [ "''${TERM:-}" != "dumb" ]; then
      GREEN=$'\033[1;32m'; BLUE=$'\033[1;34m'; YELLOW=$'\033[1;33m'; RED=$'\033[1;31m'; RESET=$'\033[0m'
    else
      GREEN=""; BLUE=""; YELLOW=""; RED=""; RESET=""
    fi
    die() { printf '%s%s%s\n' "$RED" "$*" "$RESET" >&2; exit "''${2:-1}"; }

    usage() {
      cat <<EOF
    shiny-install — guided NixOS installer for shinyflakes hosts

    Usage:
      sudo shiny-install [--host HOST] [options]

    Options:
          --host HOST                host to install (prompts if omitted)
      -u, --user USER                user to set password for   default: lucas
      -m, --mount PATH               mount point of new system  default: /mnt
      -s, --skip-disko               skip disk partitioning
      -n, --no-reboot                do not reboot after install
      -h, --help
    EOF
    }
    [ "''${1:-}" = "-h" ] || [ "''${1:-}" = "--help" ] && { usage; exit 0; }

    user="lucas"
    mount="/mnt"
    skip_disko=0
    no_reboot=0

    while [ $# -gt 0 ]; do
      case "$1" in
        --host)         host="$2";    shift 2 ;;
        -u|--user)      user="$2";    shift 2 ;;
        -m|--mount)     mount="$2";   shift 2 ;;
        -s|--skip-disko) skip_disko=1; shift ;;
        -n|--no-reboot)  no_reboot=1;  shift ;;
        -h|--help)       usage; exit 0 ;;
        --) shift; break ;;
        -*) die "unknown flag: $1" ;;
        *)  die "unexpected positional: $1" ;;
      esac
    done

    # root needed for nixos-install / mount / writes to /mnt
    [ "$(id -u)" -ne 0 ] && die "must run as root (try: sudo shiny-install)"

    ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    [ -f "$ROOT/flake.nix" ] || die "not running inside the shinyflakes repo (no flake.nix at $ROOT)"

    # prompt for host if not given
    if [ -z "''${host:-}" ]; then
      host=$(find "$ROOT/nix/hosts" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
        | sort | gum choose --header "Select host to install")
      [ -z "$host" ] && die "you must select a host to install!"
    fi

    HOST_DIR="$ROOT/nix/hosts/$host"
    [ -d "$HOST_DIR" ] || die "host '$host' has no config dir at $HOST_DIR"

    # disko device config lives in different places per host
    DISKO_FILE=""
    for f in "$HOST_DIR/disk.nix" "$HOST_DIR/modules/disk-config.nix"; do
      [ -f "$f" ] && DISKO_FILE="$f" && break
    done

    printf '%s=== shinyflakes guided NixOS installer ===%s\n\n' "$BLUE" "$RESET"
    printf '%sHost:  %s%s\n' "$GREEN" "$host" "$RESET"
    printf '%sRepo:  %s%s\n' "$GREEN" "$ROOT" "$RESET"
    if [ -n "$DISKO_FILE" ]; then
      printf '%sDisko: %s%s\n' "$GREEN" "$DISKO_FILE" "$RESET"
      # surface the configured device so it can be sanity-checked before wiping
      DEVICE_LINE=$(grep -m1 'device = ' "$DISKO_FILE" || true)
      [ -n "$DEVICE_LINE" ] && printf '%s       %s%s\n' "$YELLOW" "$DEVICE_LINE" "$RESET"
    else
      printf '%sDisko: none found for %s%s\n' "$YELLOW" "$host" "$RESET"
    fi
    printf '\n'

    # --- 1. disk partitioning -------------------------------------------------
    if [ "$skip_disko" = "1" ]; then
      printf '%sSkipping disk partitioning (--skip-disko)%s\n' "$YELLOW" "$RESET"
    elif [ -z "$DISKO_FILE" ]; then
      die "no disko config for '$host'; partition manually and pass --skip-disko"
    else
      gum confirm "This will DESTROY all data on the target disk. Continue?" \
        || die "aborted" 1
      printf '\n%sRunning disko (destroy, format, mount)...%s\n' "$BLUE" "$RESET"
      # not wrapped in gum spin: disko is verbose and we want failures visible
      nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
        --mode destroy,format,mount "$DISKO_FILE"
      printf '\n%sDisko complete. Verifying mounts...%s\n' "$GREEN" "$RESET"
      mount | grep -q "$mount" || die "nothing mounted at $mount after disko"
    fi
    printf '\n'

    # --- 2. hardware configuration -------------------------------------------
    printf '%sGenerating hardware configuration...%s\n' "$BLUE" "$RESET"
    nixos-generate-config --no-filesystems --root "$mount"
    # persist the generated hw config in the repo so it survives reinstalls
    cp "$mount/etc/nixos/hardware-configuration.nix" "$HOST_DIR/hardware-configuration.nix"
    printf '%shardware-configuration.nix written to %s%s\n' "$GREEN" "$HOST_DIR" "$RESET"
    printf '\n'

    # --- 3. copy flake onto the target ---------------------------------------
    printf '%sCopying flake (with submodules) to %s/etc/nixos ...%s\n' "$BLUE" "$mount" "$RESET"
    # copy the whole repo including .git + submodule working trees so the
    # ?submodules=1 flake ref resolves inside the install chroot
    cp -r "$ROOT/." "$mount/etc/nixos/"
    printf '%sFlake copied.%s\n' "$GREEN" "$RESET"
    printf '\n'

    # --- 4. install -----------------------------------------------------------
    gum confirm "Ready to run nixos-install?" || die "aborted" 1
    printf '%sInstalling NixOS (this takes a while)...%s\n' "$BLUE" "$RESET"
    nixos-install --no-root-password --flake "$mount/etc/nixos?submodules=1#$host"
    printf '%sNixOS installed!%s\n' "$GREEN" "$RESET"
    printf '\n'

    # --- 5. user password -----------------------------------------------------
    if gum confirm "Set password for user '$user' now?"; then
      nixos-enter --root "$mount" -- passwd "$user"
      printf '%sPassword set for %s.%s\n' "$GREEN" "$user" "$RESET"
    fi
    printf '\n'

    # --- 6. reboot ------------------------------------------------------------
    if [ "$no_reboot" = "1" ]; then
      printf '%sSkipping reboot (--no-reboot). Unmount with: umount -R %s%s\n' "$YELLOW" "$mount" "$RESET"
    elif gum confirm "Installation complete. Reboot now?"; then
      umount -R "$mount"
      reboot
    fi
  '';
}