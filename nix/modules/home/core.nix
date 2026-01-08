{
  config,
  inputs,
  pkgs,
  perSystem,
  flake,
  ...
}:
let
  pkgs-stable = import inputs.nixpkgs-stable { inherit (pkgs) system; };
  pkgs-small = import inputs.nixpkgs-small { inherit (pkgs) system; };
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    flake.modules.nixos.settings
  ];

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    age = {
      keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
    secrets = {
      shellEnv.mode = "0400";
    };
  };

  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  services.playerctld.enable = true;

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
    deploy-rs
    sshs
    termshark
    symfony-cli
    k6
    sops
    yaml-language-server
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
    cachix
    neovim
    gnupg
    mill
    sbt
    bloop
    scalafix
    scalafmt
    nil
    marp-cli
    jq
    yq
    gh # github cli
    pkgs-stable.awscli2
    kubernetes-helm
    kubectx
    kubectl
    devspace
    uv
    pipx
    impala
    claude-code
    codex
    opencode
    biome

    # gui apps
    obsidian
    pavucontrol
    notion-app-enhanced
    calibre
    localsend
    element-desktop
    diebahn
    wireguard-ui
    discord
    pkgs-small.vesktop
    slack
    signal-desktop
    thunderbird
    vlc
    fluffychat
    flatpak
    teams-for-linux
    libreoffice-qt6-fresh
    brave

    # cli apps
    glow # render markdown on the cli
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
    lsof
    wtype
    wireguard-tools
    espflash
    isd
    bluetui
    aichat
    vdhcoapp
    rustc
    cargo
    clang

    # devops
    krew
    dive # docker image explorer
    stern
    cilium-cli
    hubble
    eksctl # aws
    hcloud # hetzner cloud
    rclone
    opentofu # terraform sucks
    # terragrunt

    # tui
    spotify-player

    # http
    curl
    wget
    httpie

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
    yadm
    rsync
    ffmpeg-full
    nix-diff
    p7zip
    nixd
    compose2nix
    clang-tools
    kotlin-language-server
    terraform-ls
    stylua
    nodePackages_latest.aws-cdk
    bubblewrap
    socat
    orca-slicer
    wireguard-tools
    tree-sitter

    perSystem.self.numr
    perSystem.self.glide-browser
    perSystem.self.wg-peer
    perSystem.librepods.default
  ];
}
