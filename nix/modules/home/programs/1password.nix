_:
{
  xdg.desktopEntries."1password" = {
    name = "1Password";
    exec = "1password --ozone-platform-hint=wayland %U";
    terminal = false;
    type = "Application";
    icon = "1password";
    settings = {
      StartupWMClass = "1Password";
      Comment = "Password manager and secure wallet";
      MimeType = "x-scheme-handler/onepassword";
      Categories = "Office";
    };
  };
}
