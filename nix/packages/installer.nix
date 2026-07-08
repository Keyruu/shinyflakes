{ pkgs, perSystem, ... }:

perSystem.pog.pog.pog {
  name = "shiny-install";
  description = "Interactive guided NixOS installer for shinyflakes hosts";

  runtimeInputs = with pkgs; [
    gum
    git
    coreutils
    findutils
    util-linux
    systemd
  ];

  flags = [
    {
      name = "host";
      short = "";
      description = "host to install (one of nix/hosts/*)";
      required = true;
      argument = "HOST";
      prompt = ''find "$(git rev-parse --show-toplevel 2>/dev/null || pwd)/nix/hosts" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | gum choose --header "Select host to install"'';
      promptError = "you must select a host to install!";
    }
    {
      name = "user";
      short = "u";
      description = "user account to set a password for after install";
      default = "lucas";
      argument = "USER";
    }
    {
      name = "mount";
      short = "m";
      description = "mount point of the new system";
      default = "/mnt";
      argument = "PATH";
    }
    {
      name = "skip-disko";
      short = "s";
      bool = true;
      description = "skip disk partitioning (already done manually)";
    }
    {
      name = "no-reboot";
      short = "n";
      bool = true;
      description = "do not reboot after install";
    }
  ];

  script = helpers: with helpers; ''
    # nixos-install, mount, and writing to /mnt all need root
    if [ "$(id -u)" -ne 0 ]; then
      die "must run as root (try: sudo shiny-install)" 1
    fi

    ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    if [ ! -f "$ROOT/flake.nix" ]; then
      die "not running inside the shinyflakes repo (no flake.nix at $ROOT)" 1
    fi

    HOST_DIR="$ROOT/nix/hosts/$host"
    if [ ! -d "$HOST_DIR" ]; then
      die "host '$host' has no config dir at $HOST_DIR" 1
    fi

    # disko device config lives in different places per host
    DISKO_FILE=""
    for f in "$HOST_DIR/disk.nix" "$HOST_DIR/modules/disk-config.nix"; do
      if [ -f "$f" ]; then
        DISKO_FILE="$f"
        break
      fi
    done

    blue "=== shinyflakes guided NixOS installer ==="
    echo ""
    green "Host:  $host"
    green "Repo:  $ROOT"
    if [ -n "$DISKO_FILE" ]; then
      green "Disko: $DISKO_FILE"
      # surface the configured device so it can be sanity-checked before wiping
      DEVICE_LINE="$(grep -m1 'device = ' "$DISKO_FILE" || true)"
      [ -n "$DEVICE_LINE" ] && yellow "       $DEVICE_LINE"
    else
      yellow "Disko: none found for '$host'"
    fi
    echo ""

    # --- 1. disk partitioning -------------------------------------------------
    if [ "$skip_disko" = "1" ]; then
      yellow "Skipping disk partitioning (--skip-disko)"
    elif [ -z "$DISKO_FILE" ]; then
      die "no disko config for '$host'; partition manually and pass --skip-disko" 1
    else
      ${confirm {
        prompt = "This will DESTROY all data on the target disk. Continue?";
        exit_code = 1;
      }}
      echo ""
      blue "Running disko (destroy, format, mount)..."
      # not wrapped in gum spin: disko is verbose and we want failures visible
      nix --experimental-features "nix-command flakes" run \
        github:nix-community/disko -- \
        --mode destroy,format,mount "$DISKO_FILE"
      echo ""
      green "Disko complete. Verifying mounts..."
      mount | grep -q "$mount" || die "nothing mounted at $mount after disko" 1
    fi
    echo ""

    # --- 2. hardware configuration -------------------------------------------
    blue "Generating hardware configuration..."
    nixos-generate-config --no-filesystems --root "$mount"
    # persist the generated hw config in the repo so it survives reinstalls
    cp "$mount/etc/nixos/hardware-configuration.nix" "$HOST_DIR/hardware-configuration.nix"
    green "hardware-configuration.nix written to $HOST_DIR"
    echo ""

    # --- 3. copy flake onto the target ---------------------------------------
    blue "Copying flake (with submodules) to $mount/etc/nixos ..."
    # copy the whole repo including .git + submodule working trees so the
    # ?submodules=1 flake ref resolves inside the install chroot
    cp -r "$ROOT/." "$mount/etc/nixos/"
    green "Flake copied."
    echo ""

    # --- 4. install -----------------------------------------------------------
    ${confirm { prompt = "Ready to run nixos-install?"; exit_code = 1; }}
    blue "Installing NixOS (this takes a while)..."
    nixos-install --no-root-password --flake "$mount/etc/nixos?submodules=1#$host"
    green "NixOS installed!"
    echo ""

    # --- 5. user password -----------------------------------------------------
    if gum confirm "Set password for user '$user' now?"; then
      nixos-enter --root "$mount" -- passwd "$user"
      green "Password set for $user."
    fi
    echo ""

    # --- 6. reboot ------------------------------------------------------------
    if [ "$no_reboot" = "1" ]; then
      yellow "Skipping reboot (--no-reboot). Unmount with: umount -R $mount"
    elif gum confirm "Installation complete. Reboot now?"; then
      umount -R "$mount"
      reboot
    fi
  '';
}
