#!/usr/bin/env bash
OPTIONS="󰌾 Lock\n󰒲 Suspend\n Hibernate\n Reboot\n󰐥 Shutdown\n󰠚 Log Out"
SELECTION=$(printf "$OPTIONS" | fuzzel --dmenu --lines=6 --width=15)
case "$SELECTION" in
    *"Lock")
        loginctl lock-session
        ;;
    *"Suspend")
        loginctl lock-session & sleep 1 && systemctl suspend
        ;;
    *"Hibernate")
        loginctl lock-session & sleep 1 && systemctl hibernate
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
