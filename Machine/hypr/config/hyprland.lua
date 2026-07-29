local terminal = "kitty"
local filemanager = "nemo"
local menu = "fuzzel"
local browser = "zen-beta"
local emoji = "bemoji"
local calculator = "gnome-calculator"
-- Keybinds
hl.bind("SUPER+RETURN", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER+W", hl.dsp.window.close())
hl.bind("SUPER+L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER+ESCAPE", hl.dsp.exec_cmd(terminal .. " -e btop"))
hl.bind("SUPER+M", hl.dsp.exec_cmd("~/.config/hypr/fuzzel-power.sh"))
hl.bind("SUPER+E", hl.dsp.exec_cmd(filemanager))
hl.bind("SUPER+B", hl.dsp.exec_cmd(browser))
hl.bind("SUPER+T", hl.dsp.window.float())
hl.bind("SUPER+Period", hl.dsp.exec_cmd(emoji))
hl.bind("SUPER+SPACE", hl.dsp.exec_cmd(menu))
hl.bind("SUPER+mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER+mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER+F", hl.dsp.window.fullscreen_state({ internal = 1, client = 1, action = "toggle" }))   
hl.bind("SUPER + V", hl.dsp.exec_cmd("~/.config/hypr/cliphist-fuzzel-img.sh"))
hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output -m active --raw | satty -f - --output-filename '/home/matko/Obrázky/Screenshots/screenshot-%Y-%m-%d_%H-%M-%S.png'"))
hl.bind("SHIFT+PRINT", hl.dsp.exec_cmd("hyprshot -m region --raw | satty -f - --output-filename '/home/matko/Obrázky/Screenshots/screenshot-%Y-%m-%d_%H-%M-%S.png'"))
hl.bind("SUPER+P", hl.dsp.exec_cmd("hyprpicker --autocopy"))
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("~/.config/hypr/fuzzel-power.sh"))
local hidden_ws = "special:hidden"
hl.bind("SUPER + SHIFT + H", hl.dsp.window.move({ workspace = hidden_ws }))
hl.bind("SUPER + H", hl.dsp.workspace.toggle_special("hidden"))
hl.bind("XF86Calculator", hl.dsp.exec_cmd(calculator))
hl.bind("F6", hl.dsp.global(":_toggle_recording"))

--ALT TAB
local current_window_state = 0
hl.on("window.fullscreen", function(w)
    if w and w.fullscreen then
        current_window_state = w.fullscreen
    else
        current_window_state = 0
    end
end)
hl.bind("SUPER+TAB", function()
    if current_window_state == 1 then
        hl.dispatch(hl.dsp.window.cycle_next())
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "set" }))
    elseif current_window_state >= 2 then
        hl.dispatch(hl.dsp.window.cycle_next())
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "set" }))
    else
        hl.dispatch(hl.dsp.window.cycle_next())
    end
end)
hl.bind("SUPER+SHIFT+TAB", function()
    if current_window_state == 1 then
        hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "set" }))
    elseif current_window_state >= 2 then
        hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen", action = "set" }))
    else
        hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
    end
end)   
local arrow_directions = { left = "l", right = "r", up = "u", down = "d" }
for key, dir in pairs(arrow_directions) do
    hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = key }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.swap({ direction = dir }))
end
-- Workspaces
for i = 1, 10 do
    local code = 9 + i
    hl.bind("SUPER + code:" .. code, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + code:" .. code, hl.dsp.window.move({ workspace = i }))
end
--volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.config/hypr/volume.sh raise"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.config/hypr/volume.sh lower"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.config/hypr/volume.sh mute"))

--sepparate configs
require("monitors")
require("input")
--Env
hl.env("GNOME_SCHEMA", "org.gnome.desktop.interface")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_PLUGIN_PATH", os.getenv("HOME") .. "/.local/lib/qt-5.15.19/plugins:" .. os.getenv("HOME") .. "/.local/lib/qt-6/plugins")
hl.env("BEMOJI_PICKER_CMD", "fuzzel --dmenu")
--Animations
hl.config({
    animations = {
        enabled = true,
    },
})
hl.curve("easeSoft", { type = "bezier", points = { {0.18, 0.62}, {0.32, 1.00} } })
hl.curve("easeFade", { type = "bezier", points = { {0.28, 0.00}, {0.22, 1.00} } })
--windows
hl.animation({ leaf = "windows",    enabled = true, speed = 2.6, bezier = "easeSoft" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 2.4, bezier = "easeSoft", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.2, bezier = "easeFade", style = "slide" })
hl.animation({ leaf = "windowsMove",enabled = true, speed = 2.8, bezier = "easeSoft" })
--fading
hl.animation({ leaf = "fade",      enabled = true, speed = 2.2, bezier = "easeFade" })
hl.animation({ leaf = "fadeIn",    enabled = true, speed = 2.0, bezier = "easeSoft" })
hl.animation({ leaf = "fadeOut",   enabled = true, speed = 1.8, bezier = "easeFade" })
hl.animation({ leaf = "fadeDim",   enabled = true, speed = 1.8, bezier = "easeFade" })
hl.animation({ leaf = "fadeSwitch",enabled = true, speed = 1.4, bezier = "easeFade" })
--layers
hl.animation({ leaf = "layers",    enabled = true, speed = 2.2, bezier = "easeSoft" })
hl.animation({ leaf = "layersIn",  enabled = true, speed = 2.0, bezier = "easeSoft" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.8, bezier = "easeFade" })
--workspaces
hl.animation({ leaf = "workspaces",       enabled = true, speed = 2.4, bezier = "easeSoft", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 2.2, bezier = "easeSoft", style = "slide" })
--borders
hl.animation({ leaf = "border",     enabled = true, speed = 2.8, bezier = "easeSoft" })
hl.animation({ leaf = "borderangle",enabled = true, speed = 3.0, bezier = "easeSoft" })   
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
    },
})
--blur
hl.config({
    decoration = {
        blur = {
            enabled = true,
            size = 5,
            passes = 2,
            new_optimizations = true,
            ignore_opacity = true,
            xray = true,
            vibrancy = 0.2,
            brightness = 1.0,
            contrast = 1.0,
            
        },
    },
})
--Acessability
hl.config({
    general = {
        layout = "dwindle",
        gaps_in = 5,
        gaps_out = 10,
    },
    dwindle = {
        preserve_split = true,

        
    },
})
-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("waypaper --restore")
    hl.exec_cmd("waybar")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("xhost +si:localuser:root")
end)
--Exec
hl.on("config.reloaded", function()
    hl.exec_cmd("gsettings set local_var_GNOME_SCHEMA gtk-theme 'adw-gtk3-dark'")
    hl.exec_cmd("gsettings set local_var_GNOME_SCHEMA color-scheme 'prefer-dark'")
    hl.exec_cmd("gsettings set local_var_GNOME_SCHEMA icon-theme 'Adwaita'")
    hl.exec_cmd("gsettings set local_var_GNOME_SCHEMA cursor-theme 'Adwaita'")
    hl.exec_cmd("gsettings set local_var_GNOME_SCHEMA font-name 'JetBrainsMono Nerd Font'")
end)
--Window rules
hl.window_rule({
    match = { 
        class = "org.gnome.Calculator" 
    },
    float = true,
    center = true
})
hl.window_rule({
    match = { 
        class = "localsend" 
    },
    float = true,
    center = true,
    size = { 900, 800 }
})
hl.window_rule({
    match = { 
        class = "ytdownloader" 
    },
    float = true,
    center = true
})
hl.window_rule({
    match = { 
        class = "com.gabm.satty" 
    },
    float = true,
    center = true,
    size = { 900, 800 }
})   
hl.window_rule({
    match = { 
        class = "steam"
    },
    float = true,
    center = true
})
hl.window_rule({
    match = { 
        class = "gazelle-window" 
    },
    float = true,
    center = true,
    size = { 900, 800 }
})
hl.window_rule({
    match = { 
        class = "org.pulseaudio.pavucontrol" 
    },
    float = true,
    center = true,
    size = { 900, 800 }
})
hl.window_rule({
    match = { 
        class = "mpv" 
    },
    float = true,
    center = true,
    size = { 900, 800 }
})
hl.window_rule({
    match = { 
        class = "waypaper" 
    },
    float = true,
    center = true,
    size = { 900, 800 }
})
