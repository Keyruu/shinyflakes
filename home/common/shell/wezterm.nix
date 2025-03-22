{
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = /* lua */ ''
      local theme = "Night Owl (Gogh)"
      local scheme = wezterm.color.get_builtin_schemes()[theme]
      -- scheme.background = "#100F0F"
      local is_darwin = function()
        return wezterm.target_triple:find("darwin") ~= nil
      end

      local decorations = is_darwin() and "RESIZE" or "NONE"
      local fontSize = is_darwin() and 14.0 or 11.0

      return {
        hide_tab_bar_if_only_one_tab = true,
        font = wezterm.font_with_fallback({
          "JetBrainsMono Nerd Font",
        }),
        harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' },
        front_end = "WebGpu",
        visual_bell = {
          fade_in_duration_ms = 75,
          fade_out_duration_ms = 75,
          target = "CursorColor",
        },
        audible_bell = "Disabled",
        font_size = fontSize,
        color_schemes = {
          [theme] = scheme,
        },
        color_scheme = theme,
        -- window_background_opacity = 0.8,
        window_decorations = decorations,
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
        },
      }
    '';
  };
}
