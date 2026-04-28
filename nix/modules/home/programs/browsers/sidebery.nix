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
      inherit
        id
        name
        color
        icon
        ;
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
      ctxId,
    }:
    {
      # PanelType.tabs from src/enums.ts — numeric, not the string "tabs".
      # isTabsPanel() does a strict === check so a string here means the
      # panel imports but never registers as a tabs panel and stays hidden.
      type = 2;
      inherit id name color;
      iconSVG = "icon_tabs";
      iconIMG = "";
      iconIMGSrc = "";
      # locked = always visible, can't be removed via drag-out
      lockedPanel = true;
      skipOnSwitching = false;
      noEmpty = false;
      # new tabs in this panel auto-open in the bound container
      newTabCtx = ctxId;
      # tabs dropped onto this panel get reopened in the container
      dropTabCtx = ctxId;
      moveRules = [ ];
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
  };

  panels = {
    personal = mkPanel {
      id = "personal";
      name = "Personal";
      color = "blue";
      ctxId = "personal";
    };
    work = mkPanel {
      id = "work";
      name = "Work";
      color = "orange";
      ctxId = "work";
    };
  };

  backup = {
    # required by Sidebery's importer (Info.getMajVer); any 5.x works
    ver = "5.3.0";
    settings = {
      hideEmptyPanels = false;
    };
    inherit containers;
    sidebar = {
      inherit panels;
      # order in the nav bar; trailing buttons are Sidebery's built-in nav btns
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
