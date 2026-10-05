# Firefox reads /etc/firefox/policies/policies.json (SysConfD, build flag
# MOZ_SYSTEM_POLICIES) INSTEAD of the install-dir distribution/policies.json
# that Home Manager writes into the wrapped Firefox — first file found wins,
# no merge, no override. Aikido's agent owns the /etc file with only its
# Certificates policy, so it silently shadows everything HM declares.
# This keeps Aikido's content as base and re-layers HM's policies on top.
{ config, pkgs, ... }:
let
  home = config.users.users.lucas.home;

  merge = pkgs.writeShellApplication {
    name = "firefox-policies-merge";
    runtimeInputs = with pkgs; [
      coreutils
      jq
    ];
    text = ''
      etc=/etc/firefox/policies/policies.json
      base=/var/lib/firefox-policies/aikido.json

      exe=$(readlink -f "${home}/.nix-profile/bin/firefox") || exit 0
      ours=$(dirname "$exe")/../lib/firefox/distribution/policies.json
      [ -f "$ours" ] || exit 0
      # No /etc file = no Aikido shadowing, distribution policies.json wins.
      [ -f "$etc" ] || exit 0

      mkdir -p /var/lib/firefox-policies
      if [ ! -f "$base" ]; then
        # Bootstrap: current /etc may already be a previous merge output.
        # Strip the keys we manage to (re)construct Aikido's base.
        # ponytail: keys set by BOTH us and Aikido can't be split apart —
        # base keeps the merged value. Only matters if they ever overlap.
        jq --slurpfile o "$ours" \
          'reduce ($o[0].policies | keys[]) as $k (. ; .policies |= del(.[$k]))' \
          "$etc" > "$base"
      fi
      # Aikido-owned file never sets ExtensionSettings; a fresh rewrite by the
      # agent (update, new cert) lacks it and becomes the new base.
      if ! jq -e '.policies.ExtensionSettings' "$etc" >/dev/null; then
        cp "$etc" "$base"
      fi

      tmp=$(mktemp)
      trap 'rm -f "$tmp"' EXIT
      # Deep merge, ours wins. Only write on change so the path unit watching
      # /etc/firefox/policies doesn't re-trigger the service in a loop.
      if jq -s '.[0] * .[1]' "$base" "$ours" > "$tmp" && ! cmp -s "$tmp" "$etc"; then
        install -m644 "$tmp" "$etc"
      fi
    '';
  };
in
{
  systemd.services.firefox-policies-merge = {
    description = "Re-merge Aikido's Firefox policies over Home Manager's";
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${merge}/bin/firefox-policies-merge";
    };
    wantedBy = [ "multi-user.target" ];
  };

  # Re-merge when Home Manager switches (new Firefox store path in the user
  # profile) and when Aikido rewrites its file. Directory watches only see
  # direct children: profile-*-link symlink swaps and policies.json.
  systemd.paths.firefox-policies-merge = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathModified = [
      "${home}/.local/state/nix/profiles"
      "/etc/firefox/policies"
    ];
  };
}
