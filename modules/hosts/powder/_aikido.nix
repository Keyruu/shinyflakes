# Aikido Endpoint Protection (work requirement), run natively so the L4 eBPF
# datapath sees all host traffic. Upstream only ships .deb/.rpm; this mirrors
# their systemd unit + postinst. Token lives in state, not the store:
#   sudo aikido-doctor token set
{ pkgs, ... }:
let
  stateDir = "/var/lib/aikidosecurity/endpoint-protection";
  logDir = "/var/log/aikidosecurity/endpoint-protection";

  aikido = pkgs.stdenv.mkDerivation {
    pname = "aikido-endpoint-protection";
    version = "1.9.10";

    # Proprietary download from the Aikido dashboard, no public URL.
    src = pkgs.requireFile {
      name = "EndpointProtection-amd64.deb";
      sha256 = "1p8x14g0xpnq5nmp11hmjws4gv2pab5m2ad8b974ma7sb00ffzy1";
      message = ''
        Download EndpointProtection-amd64.deb from the Aikido dashboard, then:
          nix-store --add-fixed sha256 EndpointProtection-amd64.deb
      '';
    };

    nativeBuildInputs = with pkgs; [
      dpkg
      autoPatchelfHook
      wrapGAppsHook3
    ];
    # Only the tray UI is dynamically linked; daemon and proxies are static Go/Rust.
    buildInputs = with pkgs; [
      gtk3
      webkitgtk_4_1
      libsoup_3
      glib
      libx11
    ];

    dontUnpack = true;
    dontWrapGApps = true;

    installPhase = ''
      runHook preInstall
      dpkg-deb -x $src unpacked
      mkdir -p $out/bin
      cp -r unpacked/opt $out/
      ln -s $out/opt/aikidosecurity/endpoint-protection/bin/aikido-doctor $out/bin/aikido-doctor
      runHook postInstall
    '';

    # The daemon launches the UI by its absolute /opt path, so wrap it in place.
    postFixup = ''
      wrapGApp $out/opt/aikidosecurity/endpoint-protection/bin/endpoint-protection-ui
    '';
  };

  # Aikido installs its proxy CA via update-ca-certificates, but the NixOS trust
  # store is immutable, so the CA is pinned with security.pki instead. This only
  # verifies the pin: an unpinned or rotated CA then surfaces as Aikido's own
  # "CA install failed" instead of silently breaking TLS.
  updateCaCertificates = pkgs.writeShellApplication {
    name = "update-ca-certificates";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      gnused
    ];
    text = ''
      bundle=$(tr -d '\n' < /etc/ssl/certs/ca-certificates.crt)
      for crt in /usr/local/share/ca-certificates/*.crt; do
        [ -e "$crt" ] || continue
        if ! grep -qF "$(sed '/-----/d' "$crt" | tr -d '\n')" <<< "$bundle"; then
          echo "$crt is not in the system bundle; pin it via security.pki.certificateFiles and rebuild" >&2
          exit 1
        fi
      done
    '';
  };
in
{
  environment.systemPackages = [ aikido ];

  # The L4 proxy's self-signed MITM CA, generated on first start and persisted in
  # ${stateDir}/run/safechain-l4-proxy. If Aikido regenerates it, the shim above
  # makes it report "CA install failed": copy
  # /usr/local/share/ca-certificates/aikido-endpoint-protection.crt here and rebuild.
  security.pki.certificateFiles = [ ./aikido-ca.pem ];

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0755 root root -"
    "d ${stateDir}/run 0755 root root -"
    "d ${logDir} 0755 root root -"
    "d /usr/local/share/ca-certificates 0755 root root -"
    # Daemon hardcodes /opt/... for its proxies and UI.
    "L+ /opt/aikidosecurity/endpoint-protection - - - - ${aikido}/opt/aikidosecurity/endpoint-protection"
  ];

  systemd.services.aikido-endpoint-protection = {
    description = "Aikido Endpoint Protection";
    documentation = [ "https://aikido.dev" ];
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "systemd-tmpfiles-setup.service"
    ];

    path = with pkgs; [
      "/run/wrappers" # sudo -n -u <user> for per-user trust config + UI launch
      updateCaCertificates
      coreutils
      util-linux
      procps
      iproute2
      nssTools
      systemd
      gnugrep
      gawk
      findutils
    ];

    # Same as upstream postinst; token intentionally empty, set via aikido-doctor.
    preStart = ''
      cfg=${stateDir}/run/config.json
      if [ ! -f "$cfg" ]; then
        echo '{"token":"","disable_ui":false,"ephemeral_secrets":false,"proxy_mode":"l4"}' > "$cfg"
        chmod 0600 "$cfg"
      fi
      [ -f ${stateDir}/run/.installed_at ] || touch ${stateDir}/run/.installed_at
    '';

    serviceConfig = {
      Type = "simple";
      ExecStart = "/opt/aikidosecurity/endpoint-protection/bin/endpoint-protection";
      WorkingDirectory = stateDir;
      StandardOutput = "append:${logDir}/endpoint-protection.log";
      StandardError = "append:${logDir}/endpoint-protection.err";
      # Daemon launches the L4 proxy into a child cgroup it creates itself.
      Delegate = true;
      Restart = "always";
      RestartSec = 5;
      KillMode = "mixed";
      TimeoutStopSec = 30;
    };
    startLimitIntervalSec = 60;
    startLimitBurst = 10;
  };
}
