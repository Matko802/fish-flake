if status is-interactive
    # Commands to run in interactive sessions can go here
end
starship init fish | source
set -U fish_greeting

if test -z "$STEAM_EXTRA_COMPAT_TOOLS_PATHS"
    set -l _steam_pid (pgrep -f "ubuntu12_32/steam -srt" | head -n1)
    if test -n "$_steam_pid"
        set -l _extra (tr '\0' '\n' < /proc/$_steam_pid/environ 2>/dev/null | grep "^STEAM_EXTRA_COMPAT_TOOLS_PATHS=" | cut -d= -f2-)
        if test -n "$_extra"
            set -gx STEAM_EXTRA_COMPAT_TOOLS_PATHS $_extra
        end
    end
end
