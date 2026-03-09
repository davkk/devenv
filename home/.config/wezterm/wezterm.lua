local wezterm = require("wezterm")
local config = wezterm.config_builder()
local action = wezterm.action

-- startup
config.default_prog = { "/usr/bin/env", "zsh", "-l" }

local gpus = wezterm.gui.enumerate_gpus()
config.webgpu_preferred_adapter = gpus[1]
config.front_end = "WebGpu"
config.max_fps = 144

-- window
config.window_decorations = "NONE"
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.window_close_confirmation = "AlwaysPrompt"
config.window_frame = {
    font = wezterm.font { family = "Iosevka", weight = "Bold" },
    font_size = 16,
    active_titlebar_bg = "#000000",
    inactive_titlebar_bg = "#000000",
}

config.skip_close_confirmation_for_processes_named = {}
config.audible_bell = "Disabled"

-- colors
config.color_scheme = "neovim"
config.colors = {
    tab_bar = {
        inactive_tab_edge = "#000000",
    },
}


-- fonts
config.font = wezterm.font_with_fallback { "Iosevka" }
config.adjust_window_size_when_changing_font_size = false
config.warn_about_missing_glyphs = false
config.underline_thickness = "0.08cell"

-- tabs
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false
config.tab_max_width = 50

wezterm.on("format-tab-title", function(tab)
    return {
        { Background = { Color = "#000000" } },
        { Text = (" [%d] "):format(tab.tab_index + 1) },
    }
end)

-- key bindings
config.keys = {
    { key = "UpArrow",   mods = "SHIFT", action = action.ScrollToPrompt(-1) },
    { key = "DownArrow", mods = "SHIFT", action = action.ScrollToPrompt(1) },
}

return config
