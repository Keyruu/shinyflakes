{ config, lib, ... }:
let
  inherit (config.services) mesh;

  lanSubnet = "192.168.100.0/24";

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
      acceptLines = lib.concatMapStrings (cidr: ''
        ip saddr ${device.ip} ip daddr ${cidr} accept comment "${device.name} -> ${cidr}"
      '') cidrs;
      dropLine = ''
        ip saddr ${device.ip} ip daddr ${lanSubnet} drop comment "${device.name}: block LAN"
      '';
    in
    if cidrs == [ ] then
      dropLine
    else
      acceptLines + dropLine;

  allRules = lib.concatMapStrings deviceRules allDevices;
in
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  sops.secrets.mentatMeshKey = {
    mode = "0600";
  };

  services.mesh = {
    ip = "100.67.0.2";
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "mesh0" ];
    externalInterface = "eth0";
  };

  networking.wg-quick.interfaces = {
    "${mesh.interface}" = {
      address = [ "${mesh.ip}/24" ];
      privateKeyFile = config.sops.secrets.mentatMeshKey.path;

      peers = [
        {
          publicKey = "ctHXSXda0q3R/NjILCPkWzlJzMc9ekKKpNHpe2Avyh8=";
          allowedIPs = [ mesh.subnet ];
          endpoint = "168.119.225.165:51234";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  networking.nftables.tables.wireguard-forward = {
    family = "ip";
    content = ''
      chain forward {
        type filter hook forward priority filter; policy accept;
        ${allRules}
      }
    '';
  };
}
