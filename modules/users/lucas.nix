{ den, inputs, ... }:
{
  den.aspects.lucas = { host, ... }: {
    includes = [
      # Projects user-relevant classes (like homeManager) from the host’s aspect tree onto users who opt in.
      # Any homeManager key defined in the host aspect is forwarded to the user’s home-manager evaluation.
      den.batteries.host-aspects

      # Sets the user’s login shell at both OS and Home Manager levels.
      # Enables programs.<shell>.enable and sets users.users.<name>.shell.
      (den.batteries.user-shell "fish")

      (den.batteries.unfree [
        "obsidian"
        "slack"
        "spotify"
        "chapterskip"
      ])

      den.aspects.core
      den.aspects.core.secrets

      den.aspects.browsers

      den.aspects.terminals

      den.aspects.shell

      den.aspects.editors

      den.aspects.tools

      den.aspects.workstation
    ];

    homeManager =
      {
        pkgs,
        inputs',
        self',
        ...
      }:
      let
        stable = import inputs.nixpkgs-stable { inherit (pkgs.stdenv.hostPlatform) system; };
      in
      {
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
          pnpm_11
          just
          goreleaser
          nixfmt
          treefmt
          cachix
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
          biome

          # ai bullshit
          inputs'.llm-agents.packages.rtk
          inputs'.llm-agents.packages.codex

          # gui apps
          obsidian
          pavucontrol
          pulseaudio # pactl
          # FIXME: broken on unstable https://github.com/NixOS/nixpkgs/issues/493843
          stable.calibre
          localsend
          element-desktop
          diebahn
          vesktop
          slack
          signal-desktop
          thunderbird
          vlc
          flatpak
          libreoffice-qt6-fresh
          brave
          blender
          inkscape

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
          # FIXME: winboat fails to compile
          # winboat
          kdePackages.kdeconnect-kde
          jira-cli-go
          kdePackages.kdenlive
          kdePackages.kwave
          tea
          handy
          plezy
          spotify

          # self'.packages.numr
          # self'.packages.glide-browser
          self'.packages.wg-peer
          self'.packages.mesh-expose
          self'.packages.mdbook-to-epub
          self'.packages.llms-to-epub
          self'.packages.forge-pr
          self'.packages.hx
        ];
      };
  };
}
