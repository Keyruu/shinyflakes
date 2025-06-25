{
  config,
  inputs,
  pkgs,
  ...
}:
let
  kanata-tray = pkgs.callPackage ../../pkgs/kanata-tray.nix { };
  newerOpencode = pkgs.opencode.overrideAttrs (oldAttrs: rec {
    version = "0.0.53";
    doInstallCheck = false;

    src = pkgs.fetchFromGitHub {
      owner = "opencode-ai";
      repo = "opencode";
      rev = "v${version}";
      hash = "sha256-s17LHvyQrw2lBtZwAZu4OsrTJd+xSJXiGdSuDppGYAs=";
    };

    vendorHash = "sha256-Kcwd8deHug7BPDzmbdFqEfoArpXJb1JtBKuk+drdohM=";
  });
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    secrets = {
      shellEnv.mode = "0400";
    };
  };

  home.packages = with pkgs; [
    # development
    python3
    lua
    nodejs
    actionlint
    gitmoji-cli
    pre-commit
    git
    zig
    go # go lang
    go-task # task runner
    gradle # java build tool
    maven # java build tool
    perl
    pyenv
    quarkus
    yarn
    air
    templ
    golangci-lint
    delve
    kubie
    nixpacks
    bun
    nixos-rebuild
    deploy-rs
    sshs
    termshark
    symfony-cli
    k6
    sops
    yaml-language-server
    zig
    coursier
    metals
    hyperfine
    tmux
    upterm
    youplot
    ripgrep
    fd
    devbox
    pnpm
    just
    goreleaser
    nixfmt-rfc-style
    nixfmt-tree
    kanata-tray
    cachix

    # gui apps
    gimp
    obsidian

    # cli apps
    glow # render markdown on the cli
    qmk
    act # run github actions locally
    ansible # automation
    aws-iam-authenticator # aws
    dua # disk usage analyzer
    gitui # git ui
    htop
    killport # kill port
    lsd # better ls
    gnumake
    postgresql
    ripgrep
    sqlite
    starship
    oh-my-posh
    btop
    devenv
    minikube
    tilt
    yt-dlp
    colmena
    harlequin
    cloudlens

    # devops
    krew
    dive # docker image explorer
    stern
    cilium-cli
    hubble
    eksctl # aws
    hcloud # hetzner cloud
    rclone
    packer # image builder
    opentofu # terraform sucks
    terragrunt

    # tui
    spotify-player
    newerOpencode
    impala
    aerc

    # http
    curl
    wget
    httpie
    # playerctl broken :(

    # funny stuff
    asciiquarium
    cowsay
    cmatrix
    fortune
    lolcat

    # utils
    gnused
    watch
    tree
    inetutils
    aria2
    neofetch
    yadm
    rsync
    rclone
    ffmpeg-full
    nix-diff
    p7zip
    nixd
    compose2nix
    clang-tools
    kotlin-language-server
    terraform-ls
    stylua
  ];
}
