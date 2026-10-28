{ ... }:
{
  den.aspects.shell.herdr.homeManager =
    {
      pkgs,
      lib,
      inputs',
      self',
      user,
      ...
    }:
    let
      t = user.theme;
      fish = lib.getExe pkgs.fish;
      herdr = lib.getExe inputs'.herdr.packages.default;
      plugins = {
        "persiyanov.reviewr" = self'.packages.herdr-reviewr;
        "fullerzz.sesh" = self'.packages.herdr-sesh;
      };
    in
    {
      home.packages = [ inputs'.herdr.packages.default ] ++ builtins.attrValues plugins;

      # Linking replaces registrations in place, preserving running panes and plugin state.
      home.activation.herdrPlugins = lib.hm.dag.entryAfter [ "linkGeneration" ] (
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (id: package: ''
            run ${herdr} plugin link ${lib.escapeShellArg "${package}/share/herdr/plugins/${id}"} --enabled
          '') plugins
        )
      );

      xdg.configFile."herdr/config.toml".source = (pkgs.formats.toml { }).generate "herdr-config.toml" {
        onboarding = false;
        terminal.default_shell = fish;
        # Cold restore cannot yet preserve our task bindings or runtime-only extensions.
        session.resume_agents_on_restore = false;
        update = {
          version_check = false;
          manifest_check = false;
        };

        theme = {
          name = "catppuccin";
          custom = {
            accent = t.accent;
            panel_bg = t.background;
            sidebar_bg = t.surface;
            active_row_bg = t.elevated;
            selection_bg = t.border;
            surface0 = t.surface;
            surface1 = t.border;
            surface_dim = t.background;
            overlay0 = t.muted;
            overlay1 = t.muted;
            text = t.foreground;
            subtext0 = t.muted;
            mauve = t.colors.purple;
            green = t.colors.green;
            yellow = t.colors.yellow;
            red = t.colors.red;
            blue = t.colors.blue;
            teal = t.colors.cyan;
            peach = t.colors.orange;
          };
        };

        keys = {
          prefix = "ctrl+space";
          detach = "prefix+d";
          split_vertical = [
            "prefix+|"
            "alt+n"
          ];
          split_horizontal = "prefix+minus";
          edit_scrollback = [
            "prefix+v"
            "prefix+e"
          ];
          copy_mode = [
            "prefix+s"
            "prefix+["
          ];
          settings = "prefix+,";
          previous_tab = [
            "prefix+p"
            "alt+h"
          ];
          next_tab = [
            "prefix+n"
            "alt+l"
          ];
          move_tab_previous = "alt+i";
          move_tab_next = "alt+o";
          command = [
            {
              key = [
                "prefix+f"
                "alt+f"
              ];
              type = "popup";
              command = fish;
              description = "scratch terminal (exit to close)";
              width = "80%";
              height = "80%";
            }
            {
              key = "alt+g";
              type = "popup";
              command = lib.getExe pkgs.lazygit;
              description = "lazygit";
              width = "80%";
              height = "80%";
            }
            {
              key = "alt+s";
              type = "plugin_action";
              command = "fullerzz.sesh.open-picker";
              description = "Sesh workspace picker";
            }
            {
              key = "prefix+shift+v";
              type = "plugin_action";
              command = "persiyanov.reviewr.toggle";
              description = "Toggle reviewr diff pane";
            }
          ];
        };
      };
    };
}
