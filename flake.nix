{
  description = "Keyruu's shinyflakes";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
      "https://cache.lix.systems"
      "https://vicinae.cachix.org"
      "https://noctalia.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  inputs = {
    # Enable after flake-self-attrs is active on all machines evaluating this flake.
    # self.submodules = true;

    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-multiverse.url = "github:fzakaria/nixpkgs-multiverse";
    # FIXME: remove once cockpit-zfs builds again on nixos-unstable
    # last Hydra-green rev for cockpit-zfs-1.2.27-3
    nixpkgs-cockpit-zfs.url = "github:NixOS/nixpkgs/15de5069c4519a4fda6642462cae6a3f36795476";

    # den — dendritic module system (aspects, hosts, entities)
    import-tree.url = "github:denful/import-tree";
    den.url = "github:denful/den";
    flake-parts.url = "github:hercules-ci/flake-parts";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    crane.url = "github:ipetkov/crane/v0.24.0";
    # Fork branch with the submodule-aware flake roots (numtide/iets#303) and
    # the classic-mode global flags (numtide/iets#304).
    iets = {
      url = "github:Keyruu/iets/feat/shinyflakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    copyparty.url = "github:9001/copyparty";
    # Pinned: unfloating this would pull v0.31.0, whose Cargo.lock has hyper
    # 1.12.0 (published 2026-10-06). The registry refuses crates younger than a
    # day, so the sofka build fails. Bump once the newer crates age past 24h.
    sofka.url = "github:nklmilojevic/sofka/v0.30.0";

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # workstation
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae.url = "github:Keyruu/vicinae/fix/nix-macos";
    vicinae-extensions = {
      url = "github:Keyruu/vicinae-extensions/integration";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    herdr.url = "github:herdrdev/herdr";

    # web
    homepage.url = "git+https://git.keyruu.de/lucas/homepage";
    buymeaspezi.url = "git+https://git.keyruu.de/lucas/buymeaspezi";

    # work
    dash0-cli.url = "github:dash0hq/dash0-cli";
  };

  outputs =
    inputs:
    let
      flake = inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
    in
    flake
    // {
      # pipeline host discovery (build.yml: setup job)
      # ciSkip hosts are built locally only, kept out of the CI matrix
      lib.hostMatrix.host =
        let
          ciSkip = [ "powder" ];
        in
        builtins.filter (host: !builtins.elem host ciSkip) (builtins.attrNames flake.nixosConfigurations);
    };
}
