{ config, ... }:
{
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = # lua
      ''
        local theme = "Night Owl (Gogh)"
        local scheme = wezterm.color.get_builtin_schemes()[theme]
        scheme.background = "#100F0F"

        return {
          hide_tab_bar_if_only_one_tab = true,
          font = wezterm.font_with_fallback({
            "${config.user.font}",
          }),
          harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
          front_end = "WebGpu",
          visual_bell = {
            fade_in_duration_ms = 75,
            fade_out_duration_ms = 75,
            target = "CursorColor",
          },
          audible_bell = "Disabled",
          font_size = 11.0,
          color_schemes = {
            [theme] = scheme,
          },
          color_scheme = theme,
          -- window_background_opacity = 0.8,
          window_decorations = "NONE",
          inactive_pane_hsb = {
            saturation = 0.7,
            brightness = 0.5,
          },
          leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 },
          keys = {
            -- {
            --   mods = "CTRL",
            --   key = "n",
            --   action = wezterm.action.SpawnWindow,
            -- },
            -- {
            --   mods = "CTRL",
            --   key = "w",
            --   action = wezterm.action.CloseCurrentPane { confirm = false },
            -- },
            {
              mods = "CTRL",
              key = "z",
              action = wezterm.action.DisableDefaultAssignment,
            },
            {
              mods   = "LEADER",
              key    = "-",
              action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' }
            },
            {
              mods   = "LEADER",
              key    = "=",
              action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' }
            },
            -- rotate panes
            {
              mods = "LEADER",
              key = "0",
              action = wezterm.action.RotatePanes "Clockwise"
            },
            -- show the pane selection mode, but have it swap the active and selected panes
            {
              mods = 'LEADER',
              key = 'Space',
              action = wezterm.action.PaneSelect {
                mode = 'SwapWithActive',
              },
            },
            {
              key = 'Enter',
              mods = 'LEADER',
              action = wezterm.action.ActivateCopyMode
            }
          },
        }
      '';
  };
}
