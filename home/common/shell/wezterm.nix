{
  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = # lua
      ''
        local theme = "Night Owl (Gogh)"
        local scheme = wezterm.color.get_builtin_schemes()[theme]
        scheme.background = "#100F0F"
        local is_darwin = function()
          return wezterm.target_triple:find("darwin") ~= nil
        end

        local decorations = is_darwin() and "RESIZE" or "NONE"
        local fontSize = is_darwin() and 14.0 or 11.0

        local w = require('wezterm')

        local function is_vim(pane)
          -- this is set by the plugin, and unset on ExitPre in Neovim
          return pane:get_user_vars().IS_NVIM == 'true'
        end

        local direction_keys = {
          h = 'Left',
          j = 'Down',
          k = 'Up',
          l = 'Right',
        }

        local function split_nav(resize_or_move, key)
          return {
            key = key,
            mods = resize_or_move == 'resize' and 'META' or 'CTRL',
            action = w.action_callback(function(win, pane)
              if is_vim(pane) then
                -- pass the keys through to vim/nvim
                win:perform_action({
                  SendKey = { key = key, mods = resize_or_move == 'resize' and 'META' or 'CTRL' },
                }, pane)
              else
                if resize_or_move == 'resize' then
                  win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
                else
                  win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
                end
              end
            end),
          }
        end

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
          inactive_pane_hsb = {
            saturation = 0.7,
            brightness = 0.5,
          },
          leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 },
          keys = {
            -- move between split panes
            split_nav('move', 'h'),
            split_nav('move', 'j'),
            split_nav('move', 'k'),
            split_nav('move', 'l'),
            -- resize panes
            split_nav('resize', 'h'),
            split_nav('resize', 'j'),
            split_nav('resize', 'k'),
            split_nav('resize', 'l'),
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
