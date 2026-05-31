-- hyprlang noerror false
-- You can put custom rules here
-- Window/layer rules:
-- https://wiki.hyprland.org/Configuring/Window-Rules/
-- Workspace rules:
-- https://wiki.hyprland.org/Configuring/Workspace-Rules/

-- ######## Window rules ########

-- Enable blur for xwayland context menus
hl.window_rule({
    match = {
        class = "^()$",
               title = "^()$"
    },
    no_blur = false
})

-- Enable blur globally
hl.window_rule({
    match = { class = ".*" },
    no_blur = false
})

-- ######## UltimMC ########

hl.window_rule({
    match = { class = "^(org\\.multimc\\.UltimMC)$" },
               float = true,
               size = { 660, 650 },
               center = true
})

-- ######## MPV ########

hl.window_rule({
    match = { class = "^(mpv)$" },

               float = true,

               size = {
                   "monitor_w * 0.7",
                   "monitor_h * 0.7"
               },

               center = true,

               persistent_size = true
})

-- ######## Vesktop ########

hl.window_rule({
    match = { class = "^(vesktop)$" },

               workspace = "4 silent",

               no_initial_focus = true,

               focus_on_activate = false,

               tile = true
})

-- ######## Optional extras ########

-- Prevent screen sharing vesktop popups if desired
-- hl.window_rule({
--     match = { class = "^(vesktop)$" },
--     no_screen_share = true
-- })

-- Disable blur for all xwayland apps
-- hl.window_rule({
--     match = { xwayland = true },
--     no_blur = true
-- })
