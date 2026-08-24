{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "mesh-expose";
  runtimeInputs = [ pkgs.frp ];
  text = ''
    if [ -t 1 ] && [ -z "''${NO_COLOR:-}" ] && [ "''${TERM:-}" != "dumb" ]; then
      BLUE=$'\033[1;34m'; RED=$'\033[1;31m'; RESET=$'\033[0m'
    else
      BLUE=""; RED=""; RESET=""
    fi
    die() { printf '%s%s%s\n' "$RED" "$*" "$RESET" >&2; exit "''${2:-1}"; }

    usage() {
      cat <<EOF
    mesh-expose — tunnel a local port to https://<subdomain>.tunnel.peeraten.net

    Usage:
      mesh-expose -p PORT -d SUBDOMAIN [-t TOKEN | -f TOKEN_FILE] [options]

    Required:
      -p, --port PORT                local port to expose
      -d, --subdomain NAME           tunnel subdomain
      -t, --token TOKEN              frp auth token
      -f, --token-file FILE          path to file containing frp auth token

    Options:
          --server ADDR              frp server host     default: 100.67.0.1
      -P, --server-port PORT         frp server port     default: 7000
      -h, --help
    EOF
    }
    [ "''${1:-}" = "-h" ] || [ "''${1:-}" = "--help" ] && { usage; exit 0; }

    server="100.67.0.1"
    server_port="7000"
    token=""
    token_file=""

    while [ $# -gt 0 ]; do
      case "$1" in
        -p|--port)        port="$2";        shift 2 ;;
        -d|--subdomain)   subdomain="$2";   shift 2 ;;
        --server)         server="$2";      shift 2 ;;
        -P|--server-port) server_port="$2"; shift 2 ;;
        -f|--token-file)  token_file="$2";  shift 2 ;;
        -t|--token)       token="$2";       shift 2 ;;
        -h|--help)        usage; exit 0 ;;
        --) shift; break ;;
        -*) die "unknown flag: $1" ;;
        *)  die "unexpected positional: $1" ;;
      esac
    done

    [ -z "''${port:-}" ] && die "--port is required"
    [ -z "''${subdomain:-}" ] && die "--subdomain is required"
    if [ -z "$token" ] && [ -z "$token_file" ]; then
      die "Either --token or --token-file is required"
    fi
    if [ -n "$token_file" ]; then
      [ -f "$token_file" ] || die "Token file not found: $token_file"
      token=$(cat "$token_file")
    fi

    printf '%sExposing localhost:%s → https://%s.tunnel.peeraten.net%s\n\n' \
      "$BLUE" "$port" "$subdomain" "$RESET"

    exec frpc http \
      --server-addr "$server" \
      --server-port "$server_port" \
      --token "$token" \
      --proxy-name "$subdomain" \
      --local-port "$port" \
      --sd "$subdomain"
  '';
}