{ config, ... }:
let
  # Sidebery container config. id matches what we put in panel.newTabCtx /
  # dropTabCtx so the import wires them up correctly. cookieStoreId is left
  # blank — Sidebery's import calls browser.contextualIdentities.create()
  # and Firefox assigns the real id; Sidebery then remaps panels to it.
  mkContainer =
    {
      id,
      name,
      color,
      icon,
    }:
    {
      inherit id name color icon;
      cookieStoreId = "";
      proxified = false;
      proxy = null;
      reopenRulesActive = false;
      reopenRules = [ ];
      userAgentActive = false;
      userAgent = "";
    };

  mkPanel =
    {
      id,
      name,
      color,
      icon,
      ctxId,
      moveRules ? [ ],
    }:
    {
      # PanelType.tabs from src/enums.ts — numeric, not the string "tabs".
      # isTabsPanel() does a strict === check so a string here means the
      # panel imports but never registers as a tabs panel and stays hidden.
      type = 2;
      inherit id name color moveRules;
      iconSVG = icon;
      newTabCtx = ctxId;
      dropTabCtx = ctxId;
      iconIMG = "";
      iconIMGSrc = "";
      lockedPanel = false;
      skipOnSwitching = false;
      noEmpty = false;
      moveExcludedTo = -1;
      bookmarksFolderId = -1;
      newTabBtns = [ ];
      srcPanelConfig = null;
    };

  containers = {
    personal = mkContainer {
      id = "personal";
      name = "Personal";
      color = "blue";
      icon = "fingerprint";
    };
    work = mkContainer {
      id = "work";
      name = "Work";
      color = "orange";
      icon = "briefcase";
    };
    banking = mkContainer {
      id = "banking";
      name = "Banking";
      color = "green";
      icon = "dollar";
    };
    shopping = mkContainer {
      id = "shopping";
      name = "Shopping";
      color = "pink";
      icon = "cart";
    };
  };

  panels = {
    personal = mkPanel {
      id = "personal";
      name = "Personal";
      color = "blue";
      icon = "fingerprint";
      ctxId = "personal";
    };
    work = mkPanel {
      id = "work";
      name = "Work";
      color = "orange";
      icon = "briefcase";
      ctxId = "work";
      moveRules = [
        { id = "0RXbX7C6l6fB"; active = true; url = "myposter.atlassian.net"; name = "Atlassian"; }
        { id = "NK5P6Jnbh-fB"; active = true; url = "meet.google.com"; name = "Meet"; }
        { id = "jz7lDojXmcgB"; active = true; url = "calendar.google.com"; name = "Calendar"; }
        { id = "spJOO10EqGNN"; active = true; url = "app.datadoghq.eu"; name = "Datadog"; }
        { id = "tsnExVCbDdm-"; active = true; url = "console.aws.amazon.com"; name = "AWS"; }
      ];
    };
  };

  backup = {
    ver = "5.5.2";
    settings = {
      hideEmptyPanels = false;
      colorizeTabs = true;
      newTabCtxReopen = true;
      previewTabsPageModeFallback = "n";
      previewTabsInlineHeight = 70;
      previewTabsWinOffsetX = 6;
      previewTabsWinOffsetY = 36;
    };
    keybindings = {
      "_execute_sidebar_action" = "Ctrl+E";
      activate = "Alt+Space";
      reset_selection = "Alt+R";
      loop_panels_forwards = "Ctrl+Shift+N";
      new_tab_on_panel = "Ctrl+Space";
      new_tab_in_group = "Ctrl+Shift+Space";
      up = "Alt+Up";
      down = "Alt+Down";
      up_shift = "Alt+Shift+Up";
      down_shift = "Alt+Shift+Down";
    };
    inherit containers;
    sidebar = {
      inherit panels;
      nav = [
        "personal"
        "work"
        "add_tp"
        "search"
        "settings"
      ];
    };
  };

  backupFile = "sidebery/sidebery-data.json";
  backupPath = "${config.xdg.configHome}/${backupFile}";
in
{
  xdg.configFile.${backupFile}.text = builtins.toJSON backup;

  # Sidebery import is a <input type="file"> — can't paste, must pick a file.
  # Alias copies the path so it can be pasted into the file dialog (Ctrl+L
  # in GTK file picker).
  home.shellAliases.sidebery-config = "echo -n ${backupPath} | wl-copy && echo 'Path copied. In Sidebery: Settings → Help → Import addon data, paste path with Ctrl+L.'";
}
