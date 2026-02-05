{
  imports = [
    ./chromium.nix
    ./firefox.nix
    ./qutebrowser.nix
    ./zen.nix
  ];

  home.sessionVariables.DEFAULT_BROWSER = "switchyard";
  xdg.mimeApps =
    let
      value = "io.github.alyraffauf.Switchyard.desktop";

      associations = builtins.listToAttrs (
        map
          (name: {
            inherit name value;
          })
          [
            "application/x-extension-shtml"
            "application/x-extension-xhtml"
            "application/x-extension-html"
            "application/x-extension-xht"
            "application/x-extension-htm"
            "x-scheme-handler/unknown"
            "x-scheme-handler/mailto"
            "x-scheme-handler/chrome"
            "x-scheme-handler/about"
            "x-scheme-handler/https"
            "x-scheme-handler/http"
            "application/xhtml+xml"
            "application/json"
            "text/plain"
            "text/html"
          ]
      );
    in
    {
      associations.added = associations;
      defaultApplications = associations;
    };
}
