{
  lib,
  config,
  pkgs,
  flake,
  ...
}:
let
  inherit (config.services) mesh;
  inherit (flake.lib.cloudflare) ipv4 ipv6;
  wsCfg = mesh.client.ws;

  mkPeer = endpoint: {
    publicKey = "ctHXSXda0q3R/NjILCPkWzlJzMc9ekKKpNHpe2Avyh8=";
    allowedIPs = [ mesh.subnet ] ++ mesh.client.allowedIPs;
    inherit endpoint;
    persistentKeepalive = 25;
  };

  ip = "${pkgs.iproute2}/bin/ip";
  defaultInterface = wsCfg.defaultInterface;

  interface = mesh.interface;
  wgQuickSvc = name: "wg-quick-${name}.service";
  wstunnelSvc = "wstunnel-client-wg-tunnel.service";
  allInterfaces = [ interface "${interface}-ws" "${interface}-all-ws" ];

  meshTunnel = pkgs.writeShellApplication {
    name = "mesh-tunnel";
    runtimeInputs = with pkgs; [ systemd coreutils gnugrep ];
    text = ''
      modes=("off" "direct" "ws" "all-ws")
      interfaces=("${interface}" "${interface}-ws" "${interface}-all-ws")

      get_active() {
        for i in "${interface}" "${interface}-ws" "${interface}-all-ws"; do
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
        for i in "''${interfaces[@]}"; do
          if systemctl is-active --quiet "wg-quick-$i.service" 2>/dev/null; then
            sudo systemctl stop "wg-quick-$i.service"
          fi
        done
        if systemctl is-active --quiet "${wstunnelSvc}" 2>/dev/null; then
          sudo systemctl stop "${wstunnelSvc}"
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
            sudo systemctl start "wg-quick-${interface}.service"
            ;;
          ws)
            stop_all
            sudo systemctl start "${wstunnelSvc}"
            sudo systemctl start "wg-quick-${interface}-ws.service"
            ;;
          all-ws)
            stop_all
            sudo systemctl start "${wstunnelSvc}"
            sudo systemctl start "wg-quick-${interface}-all-ws.service"
            ;;
          *)
            echo "Unknown mode: $mode"
            exit 1
            ;;
        esac
      }

      current=$(get_active)

      if [ $# -eq 0 ]; then
        echo "Current: $current"
        echo ""
        selected=$(printf '%s\n' "''${modes[@]}" | grep -v "^$current$" | fzf --prompt="Tunnel mode: ")
        [ -z "$selected" ] && exit 0
        start_mode "$selected"
        echo "Switched to: $selected"
      else
        start_mode "$1"
        echo "Switched to: $1"
      fi
    '';
  };

  addIPv4Routes = lib.concatMapStringsSep "\n" (
    cidr: "${ip} route add ${cidr} via $GW4 dev ${defaultInterface}"
  ) ipv4;

  delIPv4Routes = lib.concatMapStringsSep "\n" (
    cidr: "${ip} route del ${cidr} via $GW4 dev ${defaultInterface} || true"
  ) ipv4;

  addIPv6Routes = lib.concatMapStringsSep "\n" (
    cidr: "${ip} -6 route add ${cidr} via $GW6 dev ${defaultInterface}"
  ) ipv6;

  delIPv6Routes = lib.concatMapStringsSep "\n" (
    cidr: "${ip} -6 route del ${cidr} via $GW6 dev ${defaultInterface} || true"
  ) ipv6;
in
{
  options.services.mesh.client = with lib.types; {
    enable = lib.mkEnableOption "enable client";
    keyName = lib.mkOption {
      type = str;
    };
    autostart = lib.mkOption {
      type = bool;
      default = true;
    };
    allowedIPs = lib.mkOption {
      type = listOf str;
      default = [ ];
    };
    ws = {
      enable = lib.mkEnableOption "enable websocket client";
      defaultInterface = lib.mkOption {
        type = str;
        description = "Default network interface used to reach the internet (for Cloudflare route exclusions)";
        example = "wlp0s20f3";
      };
    };
  };

  config = lib.mkIf mesh.client.enable {
    sops.secrets."${mesh.client.keyName}" = { };
    networking.wg-quick.interfaces = {
      "${mesh.interface}" = {
        address = [ "${mesh.ip}/24" ];
        privateKeyFile = config.sops.secrets."${mesh.client.keyName}".path;
        dns = [ "100.67.0.2" ];
        inherit (mesh.client) autostart;

        peers = [
          (mkPeer "mesh.peeraten.net:51234")
        ];
      };
      "${mesh.interface}-ws" = {
        address = [ "${mesh.ip}/24" ];
        privateKeyFile = config.sops.secrets."${mesh.client.keyName}".path;
        dns = [ "100.67.0.2" ];
        autostart = false;

        preUp = ''
          echo "trigger" > /dev/udp/127.0.0.1/51234 || true
          sleep 2
        '';

        peers = [
          (mkPeer "127.0.0.1:51234")
        ];
      };
      "${mesh.interface}-all-ws" = lib.mkIf wsCfg.enable {
        inherit (config.networking.wg-quick.interfaces."${mesh.interface}")
          address
          privateKeyFile
          dns
          ;

        autostart = false;

        preUp = ''
          # Route Cloudflare IPs via the default interface to prevent routing loops
          # (wstunnel connects to Cloudflare-proxied service.peeraten.net)
          GW4=$(${ip} route show default dev ${defaultInterface} | ${pkgs.gawk}/bin/awk '{print $3; exit}')
          GW6=$(${ip} -6 route show default dev ${defaultInterface} | ${pkgs.gawk}/bin/awk '{print $3; exit}')

          if [ -n "$GW4" ]; then
            ${addIPv4Routes}
          fi

          if [ -n "$GW6" ]; then
            ${addIPv6Routes}
          fi

          echo "trigger" > /dev/udp/127.0.0.1/51234 || true
          sleep 2
        '';

        preDown = ''
          GW4=$(${ip} route show default dev ${defaultInterface} | ${pkgs.gawk}/bin/awk '{print $3; exit}')
          GW6=$(${ip} -6 route show default dev ${defaultInterface} | ${pkgs.gawk}/bin/awk '{print $3; exit}')

          if [ -n "$GW4" ]; then
            ${delIPv4Routes}
          fi

          if [ -n "$GW6" ]; then
            ${delIPv6Routes}
          fi
        '';

        peers = [
          {
            publicKey = "ctHXSXda0q3R/NjILCPkWzlJzMc9ekKKpNHpe2Avyh8=";
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            endpoint = "127.0.0.1:51234";
            persistentKeepalive = 25;
          }
        ];
      };
    };

    environment.systemPackages = [ meshTunnel ];

    # Allow wheel users to manage tunnel services without password
    security.sudo.extraRules = [
      {
        groups = [ "wheel" ];
        commands =
          (map (i: {
            command = "/run/current-system/sw/bin/systemctl start ${wgQuickSvc i}";
            options = [ "NOPASSWD" ];
          }) allInterfaces)
          ++ (map (i: {
            command = "/run/current-system/sw/bin/systemctl stop ${wgQuickSvc i}";
            options = [ "NOPASSWD" ];
          }) allInterfaces)
          ++ lib.optionals wsCfg.enable [
            {
              command = "/run/current-system/sw/bin/systemctl start ${wstunnelSvc}";
              options = [ "NOPASSWD" ];
            }
            {
              command = "/run/current-system/sw/bin/systemctl stop ${wstunnelSvc}";
              options = [ "NOPASSWD" ];
            }
          ];
      }
    ];

    # Restart wstunnel after resume from suspend so the tunnel reconnects
    systemd.services.wstunnel-restart-on-resume = lib.mkIf wsCfg.enable {
      description = "Restart wstunnel after resume from suspend";
      after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        # Only restart if a WS tunnel is active
        if systemctl is-active --quiet ${wgQuickSvc "${interface}-ws"} || \
           systemctl is-active --quiet ${wgQuickSvc "${interface}-all-ws"}; then
          systemctl restart ${wstunnelSvc}
        fi
      '';
    };

    services.wstunnel = lib.mkIf wsCfg.enable {
      enable = true;
      clients.wg-tunnel = {
        connectTo = "wss://service.peeraten.net";
        settings = {
          local-to-remote = [
            "udp://127.0.0.1:51234:127.0.0.1:51234"
          ];
          http-upgrade-path-prefix = "api/v1/websocket";
          tls-sni-override = "service.peeraten.net";
        };
      };
    };
  };
}
