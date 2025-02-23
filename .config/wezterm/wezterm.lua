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

-- wezterm.gui is not available to the mux server, so take care to
-- do something reasonable when this config is evaluated by the mux
function get_appearance()
    if wezterm.gui then
        return wezterm.gui.get_appearance()
    end
    return 'Dark'
end

function scheme_for_appearance(appearance)
    if appearance:find 'Dark' then
        return 'PaulMillrTweaked'
    else
        return 'PaulMillrTweakedLight'
    end
end

config.font = wezterm.font 'JetBrains Mono'
config.font_size = 12.0
config.color_scheme = scheme_for_appearance(get_appearance())
config.hide_tab_bar_if_only_one_tab = true
config.native_macos_fullscreen_mode = true
config.adjust_window_size_when_changing_font_size = false
config.audible_bell = 'Disabled'

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

config.hyperlink_rules = {
    -- Linkify things that look like URLs and the host has a TLD name.
    -- Compiled-in default. Used if you don't specify hyperlink_rules.
    -- Differs from default in a way that it doesn't treat file:// as a valid URI.
    {
        regex = [[\bhttps?://[\w.-]+\.[a-z]{2,15}\S*\b]],
        format = '$0',
    },

    -- Linkify things that look like URLs with numeric addresses as hosts.
    -- E.g. http://127.0.0.1:8000 for a local development server.
    {
        regex = [[\b\w+://(?:[\d]{1,3}\.){3}[\d]{1,3}\S*\b]],
        format = '$0',
    },

    -- Gerrit Change-Ids
    {
        regex = [[\bI[0-9a-f]{40}\b]],
        format = 'https://gerrit-review.googlesource.com/q/$0',
    },
}

return config
