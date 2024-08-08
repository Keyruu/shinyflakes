{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # development
    python3
    rustup
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
    helm-ls
    air
    templ
    golangci-lint
    delve
    kubie
    nixpacks
    bun
    nixos-rebuild

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
    gh # github cli
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

    # devops
    kubectl
    krew
    dive # docker image explorer
    stern
    cilium-cli
    hubble
    eksctl # aws
    kubectx
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
    jq
    yq
    rsync
    rclone
    ffmpeg-full
    nix-diff
    p7zip
  ];
}
