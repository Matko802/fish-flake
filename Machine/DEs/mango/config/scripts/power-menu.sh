#!/usr/bin/env bash
OPTIONS="󰌾 Lock\n󰒲 Suspend\n Reboot\n󰐥 Shutdown\n󰠚 Log Out"
SELECTION=$(printf "$OPTIONS" | fuzzel --dmenu --lines=5 --width=15)
case "$SELECTION" in
    *"Lock")
        hyprlock
        ;;
    *"Suspend")
        hyprlock & sleep 1 && systemctl suspend
        ;;
    *"Reboot")
        systemctl reboot
        ;;
    *"Shutdown")
        systemctl poweroff
        ;;
    *"Log Out")
        mmsg dispatch quit
        ;;
esac
