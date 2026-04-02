{ ... }:
let
  extDir = ".pi/agent/extensions";
in
{
  home.file = {
    "${extDir}/neovim-review.ts".source = ./neovim-review.ts;
    "${extDir}/notify-done.ts".source = ./notify-done.ts;
  };
}
