{
  config,
  inputs,
  perSystem,
  ...
}:
{
  # home.nix
  imports = [
    inputs.zen-browser.homeModules.beta
    # or inputs.zen-browser.homeModules.twilight
    # or inputs.zen-browser.homeModules.twilight-official
  ];

  programs.zen-browser = {
    enable = true;
    inherit (config.programs.firefox) policies;
    profiles.default = {
      isDefault = true;
      inherit (config.programs.firefox.profiles.default) userContent;
      extensions = {
        inherit (config.programs.firefox.profiles.default.extensions) packages;
      };
      settings = config.programs.firefox.profiles.default.settings // {
        "zen.tabs.show-newtab-vertical" = false;
        "zen.urlbar.behavior" = "float";
        "zen.view.compact.enable-at-startup" = true;
        "zen.view.compact.hide-toolbar" = true;
        "zen.view.compact.toolbar-flash-popup" = false;
        "zen.view.show-newtab-button-top" = false;
        "zen.view.window.scheme" = 0;
        "zen.welcome-screen.seen" = true;
        "zen.workspaces.continue-where-left-off" = true;
      };
      search = {
        force = true;
        default = "Kagi";
        inherit (config.programs.firefox.profiles.default.search) engines;
      };
      containersForce = true;
      containers = {
        Personal = {
          color = "blue";
          icon = "fingerprint";
          id = 1;
        };
        Work = {
          color = "red";
          icon = "briefcase";
          id = 2;
        };
      };
      spacesForce = true;
      spaces =
        let
          containers = config.programs.zen-browser.profiles."default".containers;
        in
        {
          "Personal" = {
            id = "c6de089c-410d-4206-961d-ab11f988d40a";
            position = 1000;
            theme.colors = [
              {
                red = 19;
                green = 16;
                blue = 164;
              }
            ];
          };
          "Work" = {
            id = "cdd10fab-4fc5-494b-9041-325e5759195b";
            icon = "💼";
            container = containers."Work".id;
            position = 2000;
            theme.colors = [
              {
                red = 88;
                green = 30;
                blue = 0;
              }
            ];
          };
        };
    };
  };

  xdg.mimeApps =
    let
      value =
        let
          zen-browser = perSystem.zen-browser.beta; # or twilight
        in
        zen-browser.meta.desktopFileName;

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
