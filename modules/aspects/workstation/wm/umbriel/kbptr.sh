result=$(wl-kbptr --only-print -c "$HOME/.config/wl-kbptr/floating") || exit $?
read -r rect output button <<< "$result"

if [[ ! $rect =~ ^([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)$ ]]; then
  printf 'unexpected wl-kbptr result: %s\n' "$result" >&2
  exit 1
fi
x=$(( BASH_REMATCH[3] + BASH_REMATCH[1] / 2 ))
y=$(( BASH_REMATCH[4] + BASH_REMATCH[2] / 2 ))
if [[ ! $output =~ ^\+(-?[0-9]+)\+(-?[0-9]+)$ ]]; then
  printf 'unexpected wl-kbptr output: %s\n' "$result" >&2
  exit 1
fi
target_x=$(( BASH_REMATCH[1] + x ))
target_y=$(( BASH_REMATCH[2] + y ))
case $button in
  l|m|r|n) ;;
  *) printf 'unexpected wl-kbptr button: %s\n' "$result" >&2; exit 1 ;;
esac

origin=$(umbriel outputs --json | jq -er '
  [.[] | select(.enabled and .powered) | .position]
  | if length > 0 then min_by(.x + .y) | "\(.x) \(.y)" else error("no enabled output") end
')
read -r origin_x origin_y <<< "$origin"
# Umbriel ignores the virtual pointer's requested output; relative motion avoids its absolute mapping.
wlrctl pointer move -100000 -100000
wlrctl pointer move "$(( target_x - origin_x ))" "$(( target_y - origin_y ))"
case $button in
  l) wlrctl pointer click left ;;
  m) wlrctl pointer click middle ;;
  r) wlrctl pointer click right ;;
esac
