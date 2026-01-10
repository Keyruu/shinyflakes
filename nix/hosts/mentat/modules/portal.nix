{ config, lib, ... }:
let
  inherit (config.services) mesh;

  lanSubnet = "192.168.100.0/24";
  lanInterface = "eth0";

  allDevices = lib.flatten (
    lib.mapAttrsToList (
      personName: person:
      lib.mapAttrsToList (deviceName: device: {
        name = "${personName}-${deviceName}";
        inherit (device) ip publicKey;
        inherit (person) canAccess;
      }) person.devices
    ) mesh.people
  );

  resolveNetworks = accessList: map (name: mesh.networks.${name}) accessList;

  deviceRules =
    device:
    let
      cidrs = resolveNetworks device.canAccess;
    in
    if cidrs == [ ] then
      ''
        # ${device.name}: vpn only
        iptables -A wireguard-forward -s ${device.ip} -d ${lanSubnet} -j DROP
      ''
    else
      ''
        # ${device.name}: ${toString device.canAccess}
      ''
      + lib.concatMapStrings (cidr: ''
        iptables -A wireguard-forward -s ${device.ip} -d ${cidr} -j ACCEPT
      '') cidrs
      + ''
        iptables -A wireguard-forward -s ${device.ip} -d ${lanSubnet} -j DROP
      '';

  allRules = lib.concatMapStrings deviceRules allDevices;

  wgSubnet = "100.67.0.0/24";
in
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  sops.secrets.mentatPortalKey = {
    mode = "0600";
  };

  services.mesh.interface = "portal0";

  networking.wg-quick.interfaces = {
    portal0 = {
      address = [ "100.67.0.2/24" ];
      privateKeyFile = config.sops.secrets.mentatPortalKey.path;

      peers = [
        {
          publicKey = "ctHXSXda0q3R/NjILCPkWzlJzMc9ekKKpNHpe2Avyh8=";
          allowedIPs = [ wgSubnet ];
          endpoint = "168.119.225.165:51234";
          persistentKeepalive = 25;
        }
      ];

      postUp = ''
        iptables -D FORWARD -j wireguard-forward 2>/dev/null || true
        iptables -F wireguard-forward 2>/dev/null || true
        iptables -X wireguard-forward 2>/dev/null || true

        iptables -N wireguard-forward
        iptables -I FORWARD -j wireguard-forward

        ${allRules}

        iptables -A wireguard-forward -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables -t nat -A POSTROUTING -s ${wgSubnet} -o ${lanInterface} -j MASQUERADE
      '';

      postDown = ''
        iptables -D FORWARD -j wireguard-forward 2>/dev/null || true
        iptables -F wireguard-forward 2>/dev/null || true
        iptables -X wireguard-forward 2>/dev/null || true
        iptables -t nat -D POSTROUTING -s ${wgSubnet} -o ${lanInterface} -j MASQUERADE 2>/dev/null || true
      '';
    };
  };
}
