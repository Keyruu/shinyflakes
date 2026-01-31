_:
# kdl
''
  window-rule {
      geometry-corner-radius 7 7 7 7
      clip-to-geometry true
  }

  window-rule {
      match app-id=r#"^scratchpad$"#
      opacity 0.96
      default-column-width { proportion 0.88; }
      default-window-height { proportion 0.88; }
      open-floating true
      open-maximized false
  }

  window-rule {
      match app-id=r#"^clipse$"#
      default-column-width {}
  }

  window-rule {
      match app-id=r#"^zen$"#
      match app-id=r#"^zen-beta$"#
      open-on-workspace "browse"
  }

  window-rule {
      match app-id=r#"^dev.zed.Zed$"#
      open-on-workspace "ide"
  }

  window-rule {
      match app-id=r#"^org.wezfurlong.wezterm$"#
      match app-id=r#"^Alacritty$"#
      open-on-workspace "term"
  }

  window-rule {
      match app-id=r#"^spotify_player$"#
      match app-id=r#"^feishin$"#
      match app-id=r#"^spotify$"#
      match title=r#"^Picture-in-Picture$"#
      open-on-workspace "media"
      default-column-width { proportion 0.5; }
  }

  window-rule {
      match app-id=r#"^Slack$"#
      match app-id=r#"^signal$"#
      match app-id=r#"^vesktop$"#
      match app-id=r#"^fluffychat$"#
      open-on-workspace "social"
      default-column-width { proportion 0.666; }
  }

  window-rule {
      match app-id=r#"^1password$"#
      match app-id=r#"^signal$"#
      match app-id=r#"^vesktop$"#
      match app-id=r#"^fluffychat$"#
      block-out-from "screencast"
  }

  layer-rule {
      match namespace=r#"^swaync-notification-window$"#
      match namespace=r#"^noctalia-notifications.*"#
      block-out-from "screencast"
  }

  layer-rule {
      match namespace=r#"^noctalia-overview*"#
      place-within-backdrop true
  }
''
