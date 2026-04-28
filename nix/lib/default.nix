{ flake, inputs, ... }:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;

  parseIpList =
    txt:
    lib.pipe txt [
      builtins.readFile
      (lib.splitString "\n")
      (lib.filter (ip: ip != ""))
    ];

  getImages =
    hostName:
    let
      host = inputs.self.nixosConfigurations.${hostName} or null;
      containers = if host != null then host.config.virtualisation.quadlet.containers else { };
    in
    lib.mapAttrsToList (name: cfg: {
      host = hostName;
      container = name;
      inherit (cfg.containerConfig) image;
    }) containers;
in
rec {
  quadlet = {
    service = container: builtins.replaceStrings [ ".container" ] [ ".service" ] container.ref;
    name = container: lib.removeSuffix ".container" container.ref;
    alias = container: builtins.head container.containerConfig.networkAliases;
  };

  cloudflare = rec {
    ipv4Txt = builtins.fetchurl {
      url = "https://www.cloudflare.com/ips-v4";
      sha256 = "sha256-8Cxtg7wBqwroV3Fg4DbXAMdFU1m84FTfiE5dfZ5Onns=";
    };

    ipv6Txt = builtins.fetchurl {
      url = "https://www.cloudflare.com/ips-v6";
      sha256 = "sha256-np054+g7rQDE3sr9U8Y/piAp89ldto3pN9K+KCNMoKk=";
    };

    ipv4 = parseIpList ipv4Txt;
    ipv6 = parseIpList ipv6Txt;
    all = ipv4 ++ ipv6;
  };

  allImages = lib.flatten (
    map getImages [
      "mentat"
      "prime"
    ]
  );

  karaokeDomain = "einfachnextlevel.karaoke.keyruu.de";

  hostMatrix = {
    host = builtins.attrNames flake.nixosConfigurations;
  };
}
