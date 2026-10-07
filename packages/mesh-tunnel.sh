# fzf picker over mesh tunnel modes (the wg-quick tunnels defined in
# modules/aspects/workstation/mesh-client.nix). Meant to run in a
# terminal; a positional argument switches directly.
#
# --dmenu: pick via `vicinae dmenu` instead of fzf (vicinae script
# command). Switches the mode and exits silently.
#
# The interface name is configurable via MESH_INTERFACE (mesh.client
# hosts all use the default "mesh0").

# vicinae/... intentionally not in the closure — desktop app, resolved
# from the user session PATH in --dmenu mode

interface=${MESH_INTERFACE:-mesh0}
mode=fzf
[ "${1:-}" = "--dmenu" ] && mode=dmenu

modes=("off" "direct" "ws" "all-ws")
interfaces=("${interface}" "${interface}-ws" "${interface}-all-ws")
wstunnelSvc="wstunnel-client-wg-tunnel.service"

get_active() {
  for i in "${interfaces[@]}"; do
    if systemctl is-active --quiet "wg-quick-$i.service" 2>/dev/null; then
      case "$i" in
        "${interface}") echo "direct" ;;
        "${interface}-ws") echo "ws" ;;
        "${interface}-all-ws") echo "all-ws" ;;
      esac
      return
    fi
  done
  echo "off"
}

stop_all() {
  for i in "${interfaces[@]}"; do
    if systemctl is-active --quiet "wg-quick-$i.service" 2>/dev/null; then
      systemctl stop "wg-quick-$i.service"
    fi
  done
  if systemctl is-active --quiet "${wstunnelSvc}" 2>/dev/null; then
    systemctl stop "${wstunnelSvc}"
  fi
}

start_mode() {
  local mode="$1"
  case "$mode" in
    off)
      stop_all
      ;;
    direct)
      stop_all
      systemctl start "wg-quick-${interface}.service"
      ;;
    ws)
      stop_all
      systemctl start "${wstunnelSvc}"
      systemctl start "wg-quick-${interface}-ws.service"
      ;;
    all-ws)
      stop_all
      systemctl start "${wstunnelSvc}"
      systemctl start "wg-quick-${interface}-all-ws.service"
      ;;
    *)
      echo "Unknown mode: $mode"
      exit 1
      ;;
  esac
}

current=$(get_active)

if [ "$mode" = "dmenu" ]; then
  # current mode marked with ✓; re-selecting it is a no-op
  disp=$(printf '%s\n' "${modes[@]}" | sed "s/^$current\$/✓ &/")
  sel=$(vicinae dmenu --navigation-title 'mesh tunnel' \
    --placeholder 'tunnel mode' <<<"$disp") || exit 0
  sel=${sel#✓ }
  [ -n "$sel" ] || exit 0
  [ "$sel" = "$current" ] && exit 0
  start_mode "$sel"
  exit 0
fi

if [ $# -gt 0 ]; then
  start_mode "$1"
  echo "Switched to: $1"
  exit 0
fi

echo "Current: $current"
echo ""
selected=$(printf '%s\n' "${modes[@]}" | grep -v "^$current$" | fzf --prompt="Tunnel mode: ")
[ -z "$selected" ] && exit 0
start_mode "$selected"
echo "Switched to: $selected"
