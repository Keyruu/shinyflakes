{pkgs, ...}: {
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
