local options = "Lock\nSuspend\nReboot\nShutdown\nLog Out"
local selection = hl.dsp.exec_cmd("printf '" .. options .. "' | fuzzel --dmenu --lines=5 --width=15")

local actions = {
  Lock     = "hyprlock",
  Suspend  = "hyprlock & sleep 1 && systemctl suspend",
  Reboot   = "systemctl reboot",
  Shutdown = "systemctl poweroff",
  ["Log Out"] = "hyprctl dispatch exit",
}

if actions[selection] then
  hl.dsp.exec_cmd(actions[selection])
end
