-- hyprlang noerror false
-- Put general config stuff here
-- Here's a list of every variable:
-- https://wiki.hyprland.org/Configuring/Variables/

hl.config({
    general = {
        gaps_in = 1,
        gaps_out = 1,
        gaps_workspaces = 20
    },
    decoration = {
        rounding = 6,
        blur = {
            enabled = true,
            size = 4,
            xray = false,
            passes = 3,
            vibrancy = 0.1696,
            ignore_opacity = true
        }
    },
    input = {
        kb_layout = "us",
        numlock_by_default = true,
        repeat_delay = 250,
        repeat_rate = 35,
        kb_options = "keymap:XF86PickupPhone=f2",
        follow_mouse = 1,
        off_window_axis_events = 2,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = false,
            clickfinger_behavior = true,
            scroll_factor = 0.5
        }
    }
})

-- HDMI port: mirror display. To see device name, use `hyprctl monitors`
