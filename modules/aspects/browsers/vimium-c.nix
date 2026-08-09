{ ... }:
{
  den.aspects.browsers.vimium-c = {
    homeManager =
      { config, ... }:
      let
        keyMappings = [
          "#!no-check"
          "unmap <c-e>"
          ""
          "unmap t"
          "map t Vomnibar.activate preferTabs=\"new\""
          "map T Vomnibar.activateTabSelection"
          "map o Vomnibar.activateInNewTab preferTabs=\"new\""
          "map O Vomnibar.activate"
          ""
        ];

        searchEngines = [
          "k|kagi: https://kagi.com/search?q=%s Kagi"
          "np: https://search.nixos.org/packages?channel=unstable&query=%s Nix Packages"
          "no: https://search.nixos.org/options?channel=unstable&query=%s Nix Options"
          "nw: https://wiki.nixos.org/w/index.php?search=%s NixOS Wiki"
          "d|ddg|duckduckgo: https://duckduckgo.com/?q=%s DuckDuckGo"
          "gh|github: https://github.com/search?q=%s GitHub"
          "w|wiki: https://en.wikipedia.org/w/index.php?search=%s Wikipedia"
          "y|yt: https://www.youtube.com/results?search_query=%s YouTube"
          ""
        ];

        exportJson = {
          name = "Vimium C";
          "@time" = "1/1/2025, 12:00:00 AM";
          time = 1735689600000;
          environment = {
            extension = "2.12.3";
            platform = "linux";
            firefox = 149;
          };
          keyLayout = 2;
          vimSync = true;

          inherit keyMappings searchEngines;
          searchUrl = "https://kagi.com/search?q=%s Kagi";
        };

        exportFile = "vimium-c/vimium-c-data.json";
        exportPath = "${config.xdg.configHome}/${exportFile}";
      in
      {
        xdg.configFile.${exportFile}.text = builtins.toJSON exportJson;

        # Vimium-c options → Backup/Restore → "Restore from a file" → file picker.
        # Path goes to clipboard so it can be pasted into the picker via Ctrl+L.
        home.shellAliases.vimium-config = "echo -n ${exportPath} | wl-copy && echo 'Path copied. In Vimium-c options: scroll to Backup, click Restore, paste path with Ctrl+L.'";
      };
  };
}
