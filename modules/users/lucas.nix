{ den, inputs, ... }:
{
  den.aspects.lucas = { host, ... }: {
    includes = [
      # Creates OS-level user accounts (users.users.<name>) with isNormalUser and home directory.
      # Also sets home.username and home.homeDirectory for Home Manager. Works on NixOS, Darwin, and standalone Home Manager.
      den.batteries.define-user

      # Marks a user as the primary (admin-level) user. On NixOS, adds wheel and networkmanager groups.
      # On Darwin, sets system.primaryUser. On WSL, sets defaultUser.
      den.batteries.primary-user

      # Projects user-relevant classes (like homeManager) from the host’s aspect tree onto users who opt in.
      # Any homeManager key defined in the host aspect is forwarded to the user’s home-manager evaluation.
      den.batteries.host-aspects

      # Sets the user’s login shell at both OS and Home Manager levels.
      # Enables programs.<shell>.enable and sets users.users.<name>.shell.
      (den.batteries.user-shell "fish")

      den.aspects.apps."1password"
      den.aspects.apps.calendar
      den.aspects.apps.chromium
      den.aspects.apps.clipse
      den.aspects.apps.colorpicker
      den.aspects.apps.element
      den.aspects.apps.firefox
      den.aspects.apps.fish
      den.aspects.apps.foot
      den.aspects.apps.gaming
      den.aspects.apps.ghostty
      den.aspects.apps.git
      den.aspects.apps.glide
      den.aspects.apps.k9s
      den.aspects.apps.kitty
      den.aspects.apps.lazygit
      den.aspects.apps.mail
      den.aspects.apps.mpv
      den.aspects.apps.neovim
      den.aspects.apps.nh
      den.aspects.apps.nix-index-database
      den.aspects.apps.noctalia
      den.aspects.apps.repos
      den.aspects.apps.satty
      den.aspects.apps.screenshot
      den.aspects.apps.sidebery
      den.aspects.apps.spotify
      den.aspects.apps.ssh
      den.aspects.apps.system
      den.aspects.apps.television
      den.aspects.apps.tmux
      den.aspects.apps.vicinae
      den.aspects.apps.vimium-c
      den.aspects.apps.vscode
      den.aspects.apps.yazi
      den.aspects.apps.zed
      den.aspects.apps.zellij
      den.aspects.apps.zen
      den.aspects.apps.zsh

      # aspects.workstation-wide home concerns
      den.aspects.workstation.gtk
      den.aspects.workstation.idle
      den.aspects.workstation.kanshi
      den.aspects.workstation.kbptr
      den.aspects.workstation.lock
      den.aspects.workstation.niri
      den.aspects.workstation.which-key
      den.aspects.workstation.wm
    ];
    homeManager =
      {
        config,
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
          lmstudio
          # FIXME: winboat fails to compile
          # winboat
          kdePackages.kdeconnect-kde
          jira-cli-go
          kdePackages.kdenlive
          kdePackages.kwave
          tea
          handy
          plezy

          # self'.packages.numr
          # self'.packages.glide-browser
          self'.packages.wg-peer
          self'.packages.mesh-expose
          self'.packages.mdbook-to-epub
          self'.packages.llms-to-epub
          self'.packages.forge-pr
          self'.packages.hx
        ];

        # from nix/modules/home/shell/default.nix
        sops.secrets = {
          openaiKey = { };
          geminiKey = { };
          mammouthKey = { };
          opencodeKey = { };
          scalewayKey = { };
          hcloudToken = { };
          cloudflareToken = { };
          jiraToken = { };
          datadogApiKeyMp = { };
          datadogAppKeyMp = { };
          hassKey = { };
          openrouterKey = { };
          litellmMasterKey = { };
          zaiKey = { };
          minimaxKey = { };
        };
        sops.templates."shell.env".content = ''
          OPENAI_API_KEY=${config.sops.placeholder.openaiKey}
          GEMINI_API_KEY=${config.sops.placeholder.geminiKey}
          MAMMOUTH_API_KEY=${config.sops.placeholder.mammouthKey}
          OPENCODE_API_KEY=${config.sops.placeholder.opencodeKey}
          SCALEWAY_API_KEY=${config.sops.placeholder.scalewayKey}
          CLOUDFLARE_API_TOKEN=${config.sops.placeholder.cloudflareToken}
          HCLOUD_TOKEN=${config.sops.placeholder.hcloudToken}
          TF_VAR_cloudflare_api_token=${config.sops.placeholder.cloudflareToken}
          TF_VAR_hcloud_token=${config.sops.placeholder.hcloudToken}
          JIRA_API_TOKEN=${config.sops.placeholder.jiraToken}
          DATADOG_API_KEY_MP=${config.sops.placeholder.datadogApiKeyMp}
          DATADOG_APP_KEY_MP=${config.sops.placeholder.datadogAppKeyMp}
          HASS_KEY=${config.sops.placeholder.hassKey}
          OPENROUTER_API_KEY=${config.sops.placeholder.openrouterKey}
          LITELLM_BASE_URL=https://litellm.lab.keyruu.de
          LITELLM_API_KEY=${config.sops.placeholder.litellmMasterKey}
          ZAI_API_KEY=${config.sops.placeholder.zaiKey}
          MINIMAX_API_KEY=${config.sops.placeholder.minimaxKey}
        '';

        home.sessionVariables = {
          # clean up ~
          LESSHISTFILE = config.xdg.cacheHome + "/less/history";
          LESSKEY = config.xdg.configHome + "/less/lesskey";
          WINEPREFIX = config.xdg.dataHome + "/wine";

          # set default applications
          EDITOR = "nvim";
          BROWSER = "glide";
          TERMINAL = "footclient";

          # enable scrolling in git diff
          DELTA_PAGER = "less -R";

          # MANPAGER = "sh -c 'col -bx | bat -l man -p'";
          PNPM_HOME = "$HOME/.pnpm-bin";
        };

        home.shellAliases = {
          k = "kubectl";
          mv = "mv -iv";
          rm = "rm -I";
          cp = "cp -iv";
          ln = "ln -iv";
          lf = "lfub";
          gs = "git status";
          gd = "git diff";
          ga = "git add";
          gc = "git clone";
          ztab = "zellij action new-tab";
          vi = "nvim";
          ".." = "cd ..";
          "..." = "cd ../..";
          deploy-mentat = "nixos-rebuild --flake ~/shinyflakes?submodules=1#mentat switch --target-host root@192.168.100.7 --build-host root@192.168.100.7 --no-reexec";
          deploy-prime = "nixos-rebuild --flake ~/shinyflakes?submodules=1#prime switch --target-host root@prime --build-host root@prime --no-reexec";
          select-k9s = ''KUBECONFIG="$(find ~/.kube -maxdepth 1 -type f -name "*.yml" -o -name "*.yaml" -o -name "config" | fzf --prompt="Select kubeconfig: ")" k9s'';
        };

        programs = {
          starship = {
            enable = true;
            enableTransience = false;
            enableFishIntegration = false;

            settings = {
              right_format = "$time";
              kubernetes = {
                disabled = true;
              };
              time = {
                disabled = false;
              };
            };
          };

          fzf.enable = true;
          zoxide.enable = true;
          lsd = {
            enable = true;
            enableFishIntegration = true;
          };
          bat.enable = true;
          direnv.enable = true;
          mise = {
            enable = true;
            enableFishIntegration = true;
            globalConfig.settings.disable_tools = [ "aqua:aws/aws-cli" ];
          };
        };
      };
  };
}
