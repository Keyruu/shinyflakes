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

  # Kanshi shared core. Monitors hold only intrinsic bits (criteria/mode/scale);
  # position is layout-relative, so each profile supplies it. Helpers are pure
  # niri IPC and take criteria strings.
  kanshi = rec {
    monitors = {
      home = {
        criteria = "Huawei Technologies Co., Inc. XWU-CBA 0x00000001";
        mode = "2560x1440@143.972Hz";
        scale = 1.0;
      };
      tuxedo = {
        criteria = "China Star Optoelectronics Technology Co., Ltd MNE007ZA3-2 Unknown";
        mode = "2880x1800@120Hz";
        scale = 1.4;
      };
      laptop = {
        criteria = "eDP-1";
        mode = "1920x1200@60Hz";
        scale = 1.0;
      };
      work = {
        criteria = "LG Electronics LG HDR 4K 0x00073A91";
        mode = "3840x2160@59.997";
        scale = 1.4;
      };
      side = {
        criteria = "DP-2";
        mode = "1920x1080@60.042Hz";
        scale = 1.0;
      };
    };

    moveToMonitor = ws: mon: "niri msg action move-workspace-to-monitor --reference ${ws} '${mon}'";
    moveToIndex = ws: i: "niri msg action move-workspace-to-index --reference ${ws} ${toString i}";
    moveWorkspace =
      ws: mon: i:
      "${moveToMonitor ws mon} && ${moveToIndex ws i}";
    moveAllWorkspaces =
      main: sec:
      lib.concatStringsSep " && " [
        (moveWorkspace "browse" main 1)
        (moveWorkspace "work" main 2)
        (moveWorkspace "social" sec 1)
      ];
    moveAllToOne =
      mon:
      lib.concatStringsSep " && " [
        (moveWorkspace "browse" mon 1)
        (moveWorkspace "work" mon 2)
        (moveWorkspace "social" mon 3)
      ];
  };
}
