{
  xdg.desktopEntries.element-desktop = {
    name = "Element (fixed)";
    exec = "element-desktop --password-store=\"gnome-libsecret\" %u";
    icon = "element";
    type = "Application";
    categories = [
      "Network"
      "InstantMessaging"
      "Chat"
    ];
    # startupWMClass = "Element";
    mimeType = [
      "x-scheme-handler/element"
      "x-scheme-handler/io.element.desktop"
    ];
    genericName = "Matrix Client";
    comment = "Feature-rich client for Matrix.org";
  };
}
