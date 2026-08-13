case "${1:-}" in
    raise)   wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    lower)   wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute)    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
esac
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
notify-send -t 5000 -a "Volume" -h string:x-canonical-private-synchronous:volume -h int:value:"$VOL" "Volume: ${VOL}%"
[ "${1:-}" != "mute" ] && pw-play /run/current-system/sw/share/sounds/freedesktop/stereo/audio-volume-change.oga
