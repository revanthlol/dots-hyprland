-- hyprlang noerror false
-- You can put custom rules here
-- Window/layer rules:
-- https://wiki.hyprland.org/Configuring/Window-Rules/
-- Workspace rules:
-- https://wiki.hyprland.org/Configuring/Workspace-Rules/

-- ######## Window rules ########

-- Enable blur for xwayland context menus
hl.window_rule({ match = { class = "^()$", title = "^()$" }, no_blur = false })

-- Enable blur for every window
hl.window_rule({ match = { class = ".*" }, no_blur = false })

-- UltimMC floating with fixed size
hl.window_rule({ match = { class = "^(org\\.multimc\\.UltimMC)$" }, float = true })
hl.window_rule({ match = { class = "^(org\\.multimc\\.UltimMC)$" }, size = { "660", "650" } })

-- MPV floating and sizing
hl.window_rule({
    match = { class = "^(mpv)$" },
    float = true,
    size = { "(monitor_w*0.7)", "(monitor_h*0.7)" },
    center = true
})

-- Vesktop to workspace 4
hl.window_rule({ match = { class = "^(vesktop)$" }, workspace = "4" })
hl.window_rule({ match = { class = "^(vesktop)$" }, tile = true })

-- Disable blur for all xwayland apps
-- hl.window_rule({ match = { xwayland = 1 }, no_blur = false })
