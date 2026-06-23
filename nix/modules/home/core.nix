{
  config,
  inputs,
  pkgs,
  perSystem,
  flake,
  ...
}:
let
  stable = import inputs.nixpkgs-stable { inherit (pkgs.stdenv.hostPlatform) system; };
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
      # sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "glide.desktop";
      "x-scheme-handler/http" = "glide.desktop";
      "x-scheme-handler/https" = "glide.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
      "x-scheme-handler/sgnl" = "signal.desktop";
      "x-scheme-handler/signalcaptcha" = "signal.desktop";
      "video/mp4" = "mpv.desktop";
      "video/vnd.avi" = "mpv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "image/svg+xml" = "imv.desktop";
      "text/plain" = "dev.zed.Zed.desktop";
    };
  };

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  services.playerctld.enable = true;

  home.packages = with pkgs; [
    # development
    python3
    lua
    nodejs
    actionlint
    git
    zig
    go # go lang
    go-task # task runner
    yarn
    air
    templ
    golangci-lint
    delve
    bun
    deploy-rs
    sshs
    termshark
    k6
    sops
    yaml-language-server
    hyperfine
    tmux
    ripgrep
    fd
    pnpm
    just
    goreleaser
    nixfmt
    treefmt
    cachix
    neovim
    gnupg
    nil
    jq
    yq
    nb
    gh # github cli
    awscli2
    kubernetes-helm
    kubectx
    kubectl
    uv
    impala
    perSystem.llm-agents.codex
    biome

    # gui apps
    obsidian
    pavucontrol
    pulseaudio # pactl
    # FIXME: broken on unstable https://github.com/NixOS/nixpkgs/issues/493843
    stable.calibre
    localsend
    element-desktop
    diebahn
    discord
    vesktop
    slack
    signal-desktop
    thunderbird
    vlc
    flatpak
    libreoffice-qt6-fresh
    brave
    blender

    # cli apps
    glow # render markdown on the cli
    act # run github actions locally
    ansible # automation
    aws-iam-authenticator # aws
    dua # disk usage analyzer
    htop
    lsd # better ls
    gnumake
    postgresql
    sqlite
    starship
    btop
    devenv
    yt-dlp
    colmena
    # FIXME: harlequin broken on unstable
    # harlequin
    lsof
    wtype
    wireguard-tools
    espflash
    isd
    bluetui
    aichat
    # vdhcoapp
    rustc
    cargo
    clang

    # devops
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
    rsync
    ffmpeg-full
    nix-diff
    p7zip
    nixd
    clang-tools
    kotlin-language-server
    terraform-ls
    stylua
    bubblewrap
    socat
    orca-slicer
    wireguard-tools
    tree-sitter
    zerotierone
    feishin
    lmstudio
    # FIXME: winboat fails to compile
    # winboat
    kdePackages.kdeconnect-kde
    gotify-desktop
    jira-cli-go
    kdePackages.kdenlive

    # perSystem.self.numr
    # perSystem.self.glide-browser
    perSystem.self.wg-peer
    perSystem.self.mesh-expose
    # perSystem.librepods.default
    perSystem.hister.default
  ];
}
