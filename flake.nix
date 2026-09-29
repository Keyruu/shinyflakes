{
  description = "Keyruu's shinyflakes";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nixpkgs.cachix.org"
      "https://cache.numtide.com"
      "https://cache.lix.systems"
      "https://vicinae.cachix.org"
      "https://niri.cachix.org"
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    # FIXME: remove once cockpit-zfs builds again on nixos-unstable
    # last Hydra-green rev for cockpit-zfs-1.2.27-3
    nixpkgs-cockpit-zfs.url = "github:NixOS/nixpkgs/15de5069c4519a4fda6642462cae6a3f36795476";

    # den migration — runs alongside blueprint until Phase 4
    import-tree.url = "github:denful/import-tree";
    den.url = "github:denful/den";
    flake-parts.url = "github:hercules-ci/flake-parts";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";

    # infra
    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";

    comin = {
      url = "github:Keyruu/comin/feature/post-build-command";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    copyparty.url = "github:9001/copyparty";

    # workstation
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae.url = "github:vicinaehq/vicinae";
    vicinae-extensions = {
      url = "github:Keyruu/vicinae-extensions/all";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri.url = "github:sodiboo/niri-flake";

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    llm-agents.url = "github:numtide/llm-agents.nix";

    zellij = {
      url = "github:Keyruu/zellij";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # web
    homepage.url = "git+https://git.keyruu.de/lucas/homepage";
    buymeaspezi.url = "git+https://git.keyruu.de/lucas/buymeaspezi";

    # private — not submodules anymore, so the flake evaluates without auth.
    # `inputs ? X` is only true when X is in flake.lock. Collaborators without
    # git.keyruu.de access clone with an empty lock for these (or run
    # `nix flake lock` to leave them unlocked), and the private paths get
    # skipped. Locals with access run `nix flake update` to populate them.
    privateflakes = {
      url = "git+https://git.keyruu.de/lucas/privateflakes.git";
      flake = false;
    };
    agents = {
      url = "git+https://git.keyruu.de/lucas/agents.git";
      flake = false;
    };
  };

  outputs =
    inputs@{ ... }:
    let
      lib = inputs.nixpkgs.lib or inputs.flake-parts.lib;
      # Extra import roots pulled in only when the matching private input is
      # present. import-tree.addPath just appends to its scan list.
      extraPaths = lib.filter (p: p != null) [
        (if inputs ? privateflakes then inputs.privateflakes else null)
        (if inputs ? agents then inputs.agents else null)
      ];
      tree = lib.foldl' (acc: p: acc.addPath p) inputs.import-tree extraPaths;
      flake = inputs.flake-parts.lib.mkFlake { inherit inputs; } (tree ./modules);
    in
    flake
    // {
      # pipeline host discovery (build.yml: setup job)
      lib.hostMatrix.host = builtins.attrNames flake.nixosConfigurations;
    };
}
