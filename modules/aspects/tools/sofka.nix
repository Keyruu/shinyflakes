{ inputs, ... }:
{
  den.aspects.tools.sofka = {
    homeManager =
      { user, ... }:
      let
        t = user.theme;
      in
      {
        imports = [ inputs.sofka.homeManagerModules.sofka ];

        programs.sofka = {
          enable = true;

          settings = {
            aliases = {
              ss = "statefulsets";
              sec = "secrets";
              dep = "deployments";
              dp = "deployments";
            };

            plugins = [
              {
                key = "ctrl-l";
                name = "logs -f";
                command = "kubectl";
                args = [
                  "logs"
                  "-f"
                  "$NAME"
                  "-n"
                  "$NAMESPACE"
                  "--context"
                  "$CONTEXT"
                ];
                scopes = [ "pods" ];
                mutating = false;
                output = "terminal";
              }
              {
                key = "alt-l";
                name = "logs|less";
                # shell=true: placeholders arrive as positional params, never
                # spliced into the script string.
                command = ''kubectl logs -n "$1" "$2" --context "$3" | less'';
                args = [
                  "$NAMESPACE"
                  "$NAME"
                  "$CONTEXT"
                ];
                shell = true;
                scopes = [ "pods" ];
                mutating = false;
                output = "terminal";
              }
              {
                key = "shift-q";
                name = "Logs <Stern>";
                command = "stern";
                args = [
                  "--tail"
                  "50"
                  "$FILTER"
                  "-n"
                  "$NAMESPACE"
                  "--context"
                  "$CONTEXT"
                ];
                scopes = [ "pods" ];
                mutating = false;
                output = "terminal";
                requires = [ "stern" ];
              }
            ];

            # sofka's built-in `:debug` replaces the k9s netshoot plugin.
            debug = {
              image = "nicolaka/netshoot:v0.12";
              node_image = "nicolaka/netshoot:v0.12";
              command = [ "bash" ];
            };

            # skin.background = false is the k9s "transparent" skin: the views
            # inherit the terminal background. Sofka's catppuccin-mocha base
            # already matches the shinyflakes accents, so only the text/surface
            # ramp and the swatches that carry meaning need remapping.
            skin = {
              name = "catppuccin-mocha";
              background = false;
              colors = {
                rosewater = t.colors.magenta;
                flamingo = t.colors.orange;
                pink = t.colors.magenta;
                mauve = t.colors.purple;
                red = t.colors.red;
                maroon = t.colors.red;
                peach = t.colors.orange;
                yellow = t.colors.yellow;
                green = t.colors.green;
                teal = t.colors.cyan;
                sky = t.colors.cyan;
                sapphire = t.accent;
                blue = t.colors.blue;
                lavender = t.colors.purple;
                text = t.foreground;
                subtext1 = t.foreground;
                subtext0 = t.muted;
                overlay1 = t.muted;
                overlay0 = t.muted;
                surface2 = t.muted;
                surface1 = t.border;
                surface0 = t.surface;
                base = t.background;
                mantle = t.background;
                crust = t.background;
              };
            };
          };
        };
      };
  };
}
