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
    };
  };
}
