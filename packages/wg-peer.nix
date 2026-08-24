{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "wg-peer";
  runtimeInputs = with pkgs; [
    coreutils
    gnugrep
    qrencode
    wireguard-tools
  ];
  text = ''
    if [ -t 1 ] && [ -z "''${NO_COLOR:-}" ] && [ "''${TERM:-}" != "dumb" ]; then
      GREEN=$'\033[1;32m'; BLUE=$'\033[1;34m'; YELLOW=$'\033[1;33m'; PURPLE=$'\033[1;35m'; RED=$'\033[1;31m'; RESET=$'\033[0m'
    else
      GREEN=""; BLUE=""; YELLOW=""; PURPLE=""; RED=""; RESET=""
    fi
    debug() { [ -n "''${VERBOSE:-}" ] && printf '%s%s%s\n' "$PURPLE" "$*" "$RESET" >&2; }
    die() { printf '%s%s%s\n' "$RED" "$*" "$RESET" >&2; exit "''${2:-1}"; }

    usage() {
      cat <<EOF
    wg-peer — provision a WireGuard peer and emit config

    Usage:
      cat server_private.key | wg-peer -e HOST:PORT -p PEER_IP/CIDR [options]

    Required:
      -e, --endpoint HOST:PORT       server endpoint
      -p, --peer-address IP/CIDR     peer tunnel address

    Options:
      -a, --allowed-ips CIDRS        LIST   default: "100.67.0.0/24, 192.168.100.0/24"
      -d, --dns DNS                  LIST   default: 100.67.0.2
      -k, --keepalive SECONDS        STR    default: 25 (0 disables)
      -m, --mtu MTU                  STR
      -o, --output FILE              PATH
      -q, --qrcode                          show QR code
      -s, --serverconfig                     emit server-side peer block
      -v, --verbose
      -h, --help
    EOF
    }
    [ "''${1:-}" = "-h" ] || [ "''${1:-}" = "--help" ] && { usage; exit 0; }

    endpoint=""; peer_address=""; mtu=""; output=""
    allowed_ips="100.67.0.0/24, 192.168.100.0/24"
    dns="100.67.0.2"
    keepalive="25"
    qrcode=0
    serverconfig=0

    while [ $# -gt 0 ]; do
      case "$1" in
        -e|--endpoint)     endpoint="$2";     shift 2 ;;
        -a|--allowed-ips)  allowed_ips="$2";  shift 2 ;;
        -p|--peer-address) peer_address="$2"; shift 2 ;;
        -d|--dns)          dns="$2";          shift 2 ;;
        -k|--keepalive)    keepalive="$2";    shift 2 ;;
        -m|--mtu)          mtu="$2";          shift 2 ;;
        -o|--output)       output="$2";       shift 2 ;;
        -q|--qrcode)       qrcode=1;          shift ;;
        -s|--serverconfig) serverconfig=1;    shift ;;
        -v|--verbose)      VERBOSE=1;         shift ;;
        -h|--help)         usage; exit 0 ;;
        --) shift; break ;;
        -*) die "unknown flag: $1" ;;
        *)  die "unexpected positional: $1" ;;
      esac
    done

    [ -t 0 ] && die "Server private key must be provided via stdin"
    [ -z "$endpoint" ] && die "--endpoint is required"
    [ -z "$peer_address" ] && die "--peer-address is required"

    SERVER_PRIVATE_KEY=$(cat)
    [ -z "$SERVER_PRIVATE_KEY" ] && die "Server private key cannot be empty"
    printf '%s' "$SERVER_PRIVATE_KEY" | grep -qE '^[A-Za-z0-9+/]{43}=$' \
      || die "Invalid server private key format"

    debug "Deriving server public key"
    SERVER_PUBLIC_KEY=$(printf '%s' "$SERVER_PRIVATE_KEY" | wg pubkey)
    [ -z "$SERVER_PUBLIC_KEY" ] && die "Failed to derive server public key"
    printf '%sServer public key: %s%s\n' "$GREEN" "$SERVER_PUBLIC_KEY" "$RESET"

    debug "Generating peer keypair"
    PEER_PRIVATE_KEY=$(wg genkey)
    PEER_PUBLIC_KEY=$(printf '%s' "$PEER_PRIVATE_KEY" | wg pubkey)
    printf '%sPeer keypair generated%s\n' "$GREEN" "$RESET"

    CONFIG="[Interface]
    PrivateKey = $PEER_PRIVATE_KEY
    Address = $peer_address"
    [ -n "$dns" ] && CONFIG="$CONFIG
    DNS = $dns"
    [ -n "$mtu" ] && CONFIG="$CONFIG
    MTU = $mtu"
    CONFIG="$CONFIG
    [Peer]
    PublicKey = $SERVER_PUBLIC_KEY
    Endpoint = $endpoint
    AllowedIPs = $allowed_ips"
    [ "$keepalive" != "0" ] && CONFIG="$CONFIG
    PersistentKeepalive = $keepalive"

    printf '\n%s=== PEER CONFIGURATION ===%s\n\n%s\n\n' "$BLUE" "$RESET" "$CONFIG"

    if [ -n "$output" ]; then
      printf '%s' "$CONFIG" > "$output"
      chmod 600 "$output"
      printf '%sConfiguration written to: %s%s\n' "$GREEN" "$output" "$RESET"
    fi

    if [ "$qrcode" = "1" ]; then
      printf '\n%s=== QR CODE ===%s\n\n' "$BLUE" "$RESET"
      printf '%s' "$CONFIG" | qrencode -t ANSIUTF8
    fi

    if [ "$serverconfig" = "1" ]; then
      printf '\n%s=== ADD THIS TO YOUR SERVER CONFIG ===%s\n\n' "$BLUE" "$RESET"
      printf '[Peer]\nPublicKey = %s\nAllowedIPs = %s\n\n' "$PEER_PUBLIC_KEY" "$peer_address"
      printf '%sRemember to reload WireGuard on the server!%s\n' "$YELLOW" "$RESET"
    fi

    printf '\n%s=== SUMMARY ===%s\nPeer Address:    %s\nPeer Public Key: %s\nServer Endpoint: %s\n\n' \
      "$GREEN" "$RESET" "$peer_address" "$PEER_PUBLIC_KEY" "$endpoint"
  '';
}