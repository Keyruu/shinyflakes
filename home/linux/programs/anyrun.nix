{inputs, pkgs, ...}: {
  imports = [ inputs.anyrun.homeManagerModules.default ];

  programs.anyrun = {
    enable = true;
    config = {
      x = { fraction = 0.5; };
      y = { fraction = 0.3; };
      width = { fraction = 0.3; };
      hideIcons = false;
      # ignoreExclusiveZones = false;
      # layer = "overlay";
      # hidePluginInfo = false;
      # closeOnClick = false;
      # showResultsImmediately = false;
      # maxEntries = null;

      plugins = with inputs.anyrun.packages.${pkgs.system}; [
        applications
        dictionary
        randr
        rink
        shell
        stdin
        symbols
        translate
        websearch
      ];
    };

    # Inline comments are supported for language injection into
    # multi-line strings with Treesitter! (Depends on your editor)
    extraCss = /* css */ ''
    '';
  };
}
