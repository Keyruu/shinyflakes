{ pkgs, perSystem, ... }:

perSystem.pog.pog.pog {
  name = "wg-peer";
  description = "Provision new WireGuard peers and generate configurations";

  flags = [
    {
      name = "endpoint";
      short = "e";
      description = "server endpoint (host:port)";
      required = true;
      argument = "ENDPOINT";
    }
    {
      name = "allowed-ips";
      short = "a";
      description = "allowed IPs (comma-sep)";
      default = "100.67.0.0/24, 192.168.100.0/24";
      argument = "IPS";
    }
    {
      name = "peer-address";
      short = "p";
      description = "peer IP (e.g. 10.0.0.2/32)";
      required = true;
      argument = "ADDRESS";
    }
    {
      name = "dns";
      short = "d";
      description = "DNS servers (comma-sep)";
      default = "100.67.0.2";
      argument = "DNS";
    }
    {
      name = "keepalive";
      short = "k";
      description = "keepalive interval (0=off)";
      default = "25";
      argument = "SECONDS";
    }
    {
      name = "mtu";
      short = "m";
      description = "interface MTU";
      argument = "MTU";
    }
    {
      name = "output";
      short = "o";
      description = "output file path";
      argument = "FILE";
    }
    {
      name = "qrcode";
      short = "q";
      bool = true;
      description = "show QR code";
    }
    {
      name = "serverconfig";
      short = "s";
      bool = true;
      description = "show server peer block";
    }
  ];

  script = ''
    if [ -t 0 ]; then
      die "Server private key must be provided via stdin"
    fi

    SERVER_PRIVATE_KEY=$(${pkgs.coreutils}/bin/cat)

    if [ -z "$SERVER_PRIVATE_KEY" ]; then
      die "Server private key cannot be empty"
    fi

    # validate the private key (base64, 44 chars with =)
    if ! echo "$SERVER_PRIVATE_KEY" | ${pkgs.gnugrep}/bin/grep -qE '^[A-Za-z0-9+/]{43}=$'; then
      die "Invalid server private key format"
    fi

    debug "Deriving server public key from provided private key"

    SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | ${pkgs.wireguard-tools}/bin/wg pubkey)

    if [ -z "$SERVER_PUBLIC_KEY" ]; then
      die "Failed to derive server public key"
    fi

    green "Server public key derived: $SERVER_PUBLIC_KEY"

    debug "Generating new peer keypair"

    PEER_PRIVATE_KEY=$(${pkgs.wireguard-tools}/bin/wg genkey)
    PEER_PUBLIC_KEY=$(echo "$PEER_PRIVATE_KEY" | ${pkgs.wireguard-tools}/bin/wg pubkey)

    green "Peer keypair generated"
    debug "Peer public key: $PEER_PUBLIC_KEY"

    CONFIG="[Interface]
    PrivateKey = $PEER_PRIVATE_KEY
    Address = $peer_address"

    if [ -n "$dns" ]; then
      CONFIG="$CONFIG
    DNS = $dns"
    fi

    if [ -n "$mtu" ]; then
      CONFIG="$CONFIG
    MTU = $mtu"
    fi

    CONFIG="$CONFIG
    [Peer]
    PublicKey = $SERVER_PUBLIC_KEY
    Endpoint = $endpoint
    AllowedIPs = $allowed_ips"

    if [ "$keepalive" != "0" ]; then
      CONFIG="$CONFIG
    PersistentKeepalive = $keepalive"
    fi

    echo ""
    blue "=== PEER CONFIGURATION ==="
    echo ""
    echo "$CONFIG"
    echo ""

    if [ -n "$output" ]; then
      echo "$CONFIG" > "$output"
      ${pkgs.coreutils}/bin/chmod 600 "$output"
      green "Configuration written to: $output"
    fi

    if [ "$qrcode" = "1" ]; then
      echo ""
      blue "=== QR CODE ==="
      echo ""
      echo "$CONFIG" | ${pkgs.qrencode}/bin/qrencode -t ANSIUTF8
    fi

    if [ "$serverconfig" = "1" ]; then
      echo ""
      blue "=== ADD THIS TO YOUR SERVER CONFIG ==="
      echo ""
      echo "[Peer]"
      echo "PublicKey = $PEER_PUBLIC_KEY"
      echo "AllowedIPs = $peer_address"
      echo ""
      yellow "Remember to reload WireGuard on the server!"
    fi

    echo ""
    green "=== SUMMARY ==="
    echo "Peer Address:    $peer_address"
    echo "Peer Public Key: $PEER_PUBLIC_KEY"
    echo "Server Endpoint: $endpoint"
    echo ""
  '';
}
