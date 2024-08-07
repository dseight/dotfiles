local wezterm = require 'wezterm'
local config = wezterm.config_builder()

local is_darwin = function()
    return wezterm.target_triple:find('darwin') ~= nil
end

if is_darwin() then
    local shell = '/opt/homebrew/bin/fish'
    config.set_environment_variables = { SHELL = shell }
    config.default_prog = { shell, '-l' }
end

-- Style

config.font = wezterm.font 'JetBrains Mono'
config.font_size = 12.0
config.color_scheme = 'PaulMillrTweaked'
config.hide_tab_bar_if_only_one_tab = true
config.native_macos_fullscreen_mode = true
config.adjust_window_size_when_changing_font_size = false

-- Navigation

local nav_key = is_darwin() and 'CMD' or 'ALT'

config.keys = {
    {
        key = 'h',
        mods = nav_key,
        action = wezterm.action.ActivatePaneDirection 'Left',
    },
    {
        key = 'j',
        mods = nav_key,
        action = wezterm.action.ActivatePaneDirection 'Down',
    },
    {
        key = 'k',
        mods = nav_key,
        action = wezterm.action.ActivatePaneDirection 'Up',
    },
    {
        key = 'l',
        mods = nav_key,
        action = wezterm.action.ActivatePaneDirection 'Right',
    },
    {
        key = 'd',
        mods = nav_key,
        action = wezterm.action.SplitHorizontal,
    },
    {
        key = 'd',
        mods = 'SHIFT|' .. nav_key,
        action = wezterm.action.SplitVertical,
    },
    {
        key = 'Enter',
        mods = 'SHIFT|' .. nav_key,
        -- TODO: add some indication of pane being zoomed
        action = wezterm.action.TogglePaneZoomState,
    },
    {
        key = 'Enter',
        mods = nav_key,
        action = wezterm.action.ToggleFullScreen,
    },
}

config.mouse_bindings = {
    -- Change the default click behavior so that it only selects
    -- text and doesn't open hyperlinks
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = 'NONE',
        action = wezterm.action.CompleteSelection 'PrimarySelection',
    },
    -- Ctrl/CMD-click will open the link under the mouse cursor
    {
        event = { Up = { streak = 1, button = 'Left' } },
        mods = is_darwin() and 'CMD' or 'CTRL',
        action = wezterm.action.OpenLinkAtMouseCursor,
    },
    -- Disable the 'Down' event of CTRL/CMD-click to avoid weird program
    -- behaviors
    {
        event = { Down = { streak = 1, button = 'Left' } },
        mods = is_darwin() and 'CMD' or 'CTRL',
        action = wezterm.action.Nop,
    },
}

return config
