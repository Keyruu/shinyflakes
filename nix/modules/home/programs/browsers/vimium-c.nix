{ config, ... }:
let
  # Vimium-c keymap config. Custom binds for t/T/o/O so they go through the
  # vomnibar (matches the previous policy block), plus unmap of <c-e> which
  # vimium-c uses as scrollDown by default and conflicts with shell editing
  # in any focused input.
  keyMappings = ''
    unmap <c-e>

    unmap t
    map t Vomnibar.activate preferTabs="new"
    map T Vomnibar.activateTabSelection
    map o Vomnibar.activateInNewTab preferTabs="new"
    map O Vomnibar.activate
  '';

  # Format: "alias|alias2: URL Description". %s is the query.
  # First entry is what searchUrl points at — used as the default engine.
  searchEngines = ''
    k|kagi: https://kagi.com/search?q=%s Kagi
    np: https://search.nixos.org/packages?channel=unstable&query=%s Nix Packages
    no: https://search.nixos.org/options?channel=unstable&query=%s Nix Options
    nw: https://wiki.nixos.org/w/index.php?search=%s NixOS Wiki
    d|ddg|duckduckgo: https://duckduckgo.com/?q=%s DuckDuckGo
    gh|github: https://github.com/search?q=%s GitHub
    w|wiki: https://en.wikipedia.org/w/index.php?search=%s Wikipedia
    y|yt: https://www.youtube.com/results?search_query=%s YouTube
  '';

  # Vimium-c's import accepts the same JSON shape it exports: metadata at the
  # top + arbitrary AllowedOptions keys. Unknown keys get ignored, missing
  # keys fall back to defaults.
  exportJson = {
    name = "Vimium C";
    # ver string — matches example export; importer logs but doesn't reject
    environment = {
      extension = "2.12.3";
      platform = "linux";
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
}
