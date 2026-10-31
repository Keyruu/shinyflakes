{ inputs, ... }:
let
  pkgs = import inputs.nixpkgs { system = "aarch64-linux"; };
  keys = pkgs.writeText "termux.properties" ''
    extra-keys = ${
      builtins.toJSON [
        [
          "DRAWER"
          {
            macro = "ALT s";
            display = "sesh";
          }
          {
            macro = "ALT h";
            display = "prev";
          }
          {
            macro = "ALT l";
            display = "next";
          }
          {
            macro = "CTRL SPACE z";
            display = "zoom";
          }
          {
            macro = "CTRL SPACE d";
            display = "detach";
          }
        ]
        [
          "ESC"
          "/"
          "-"
          "UP"
          "ALT"
          "ENTER"
        ]
        [
          "TAB"
          "CTRL"
          "LEFT"
          "DOWN"
          "RIGHT"
          "KEYBOARD"
        ]
      ]
    }
  '';
in
{
  flake.nixOnDroidConfigurations.default = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
    inherit pkgs;
    modules = [
      ({ config, ... }: {
        system.stateVersion = "24.05";
        user.shell = "${pkgs.fish}/bin/fish";
        nix.extraOptions = "experimental-features = nix-command flakes";
        terminal.font = "${pkgs.maple-mono.NormalNL-NF}/share/fonts/truetype/MapleMonoNormalNL-NF-Regular.ttf";
        environment.packages = with pkgs; [
          openssh
          mosh
          git
        ];

        home-manager = {
          config = {
            home.stateVersion = "24.05";
            programs = {
              fish = {
                enable = true;
                shellAliases = {
                  storage = "cd /storage/emulated/0";
                  rebuild = "nix-on-droid switch --flake '/storage/emulated/0/Syncthing/shinyflakes?submodules=1'";
                };
              };
              starship = {
                enable = true;
                enableFishIntegration = true;
              };
              git = {
                enable = true;
                package = null;
                settings.safe.directory = [
                  "/storage/emulated/0/Syncthing/shinyflakes"
                  "/storage/emulated/0/Syncthing/shinyflakes/modules/aspects/agents"
                  "/storage/emulated/0/Syncthing/shinyflakes/modules/aspects/private"
                ];
              };
              zoxide.enable = true;
              ssh = {
                enable = true;
                enableDefaultConfig = false;
                settings = {
                  powder = {
                    HostName = "192.168.100.134";
                    User = "lucas";
                    Port = 2222;
                    StrictHostKeyChecking = "ask";
                  };
                  "*" = {
                    ForwardAgent = false;
                    AddKeysToAgent = "no";
                    Compression = false;
                    ServerAliveInterval = 0;
                    ServerAliveCountMax = 3;
                    HashKnownHosts = false;
                    UserKnownHostsFile = "~/.ssh/known_hosts";
                    ControlMaster = "no";
                    ControlPath = "~/.ssh/master-%r@%n:%p";
                    ControlPersist = "no";
                  };
                };
              };
            };
          };
        };

        # The app reads this file outside proot; a symlink into /nix/store is invisible there.
        build.activationAfter.termuxKeys = ''
          target="${config.user.home}/.termux/termux.properties"
          $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
          if [ -e "$target" ] && [ ! -e "$target.bak" ]; then
            $DRY_RUN_CMD cp -p "$target" "$target.bak"
          fi
          $DRY_RUN_CMD cp --remove-destination ${keys} "$target"
        '';
      })
    ];
  };
}
