{ pkgs, qute-profile }:
pkgs.writeShellApplication {
  name = "qute-open";
  runtimeInputs = [ qute-profile pkgs.vicinae ];
  text = ''
    URL="''${1:-}"

    PROFILE=$(printf "personal\nwork" | vicinae dmenu -p "Open in:")

    [ -z "$PROFILE" ] && exit 0

    exec qute-profile launch "$PROFILE" "$URL"
  '';
}
