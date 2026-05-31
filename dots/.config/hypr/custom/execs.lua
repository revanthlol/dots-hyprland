-- hyprlang noerror false
-- You can make apps auto-start here
-- Relevant Hyprland wiki section:
-- https://wiki.hyprland.org/Configuring/Keywords/#executing

-- Input method
-- hl.exec_cmd("fcitx5")
hl.on("hyprland.start", function()

-- startup apps
hl.exec_cmd("vesktop")

-- custom lua startup scripts
require("custom.scripts.mpv")
require("custom.scripts.kitty")

end)
