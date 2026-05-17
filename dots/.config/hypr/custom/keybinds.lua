local qsIpcCall = "qs -c $qsConfig ipc call"

-- User config shortcuts
hl.bind("CTRL + SUPER + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json"),
    { description = "Edit shell config" })
hl.bind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
    { description = "Edit extra keybinds" })

-- Launcher
hl.bind("SUPER + Space", hl.dsp.exec_cmd("pkill fuzzel || fuzzel"), { description = "App launcher" })

-- Audio and brightness
hl.bind("ALT + X", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+"),
    { locked = true, repeating = true, description = "Increase volume" })
hl.bind("ALT + Z", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),
    { locked = true, repeating = true, description = "Decrease volume" })
hl.bind("ALT + comma", hl.dsp.exec_cmd(qsIpcCall .. " brightness decrement || brightnessctl s 5%-"),
    { locked = true, repeating = true, description = "Decrease brightness" })
hl.bind("ALT + Period", hl.dsp.exec_cmd(qsIpcCall .. " brightness increment || brightnessctl s 5%+"),
    { locked = true, repeating = true, description = "Increase brightness" })
hl.bind("ALT + S", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"),
    { locked = true, description = "Mute volume" })

-- Screen snip
hl.bind("Menu", hl.dsp.global("quickshell:regionScreenshot"), { description = "Screenshot" })
hl.bind("Menu", hl.dsp.exec_cmd(qsIpcCall .. " TEST_ALIVE || pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"),
    { locked = true, non_consuming = true, description = "Screen snip (fallback)" })

-- Workspace paging
hl.bind("SUPER + ALT + Z", hl.dsp.focus({ workspace = "r-10" }), { description = "Workspace: Page back" })
hl.bind("SUPER + ALT + X", hl.dsp.focus({ workspace = "r+10" }), { description = "Workspace: Page forward" })
