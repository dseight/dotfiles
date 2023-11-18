local wezterm = require 'wezterm'

return {
    initial_rows = 46,
    initial_cols = 161,

    font = wezterm.font 'JetBrains Mono',
    font_size = 12.0,
    color_scheme = 'PaulMillrTweaked',
    enable_tab_bar = false,
    audible_bell = 'Disabled',

    mouse_bindings = {
        -- Change the default click behavior so that it only selects
        -- text and doesn't open hyperlinks
        {
            event = { Up = { streak = 1, button = 'Left' } },
            mods = 'NONE',
            action = wezterm.action.CompleteSelection 'PrimarySelection',
        },
        -- Ctrl-click will open the link under the mouse cursor
        {
            event = { Up = { streak = 1, button = 'Left' } },
            mods = 'CTRL',
            action = wezterm.action.OpenLinkAtMouseCursor,
        },
        -- Disable the 'Down' event of Ctrl-click to avoid weird program
        -- behaviors
        {
            event = { Down = { streak = 1, button = 'Left' } },
            mods = 'CTRL',
            action = wezterm.action.Nop,
        },
    }
}
