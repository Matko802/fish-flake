.pragma library

// Icon theme resolver backed by a generated catalog (below). Each logical icon
// name maps to a concrete relative path per installed theme, so resolving is
// deterministic and instant - no runtime filesystem probing, no log spam. The
// selected theme is swapped live from the settings menu; icons missing from the
// active pack fall back to another installed pack (e.g. battery levels fall
// back to Adwaita when Papirus is selected, as Papirus lacks level variants).

const CATALOG = {
  "cpu": { "Papirus-Dark": "22x22/devices/cpu.svg", "Papirus": "22x22/devices/cpu.svg", "Papirus-Light": "22x22/devices/cpu.svg" },
  "memory": { "Papirus-Dark": "22x22/devices/memory.svg", "Papirus": "22x22/devices/memory.svg", "Papirus-Light": "22x22/devices/memory.svg" },
  "disk": { "Papirus-Dark": "22x22/devices/drive-harddisk.svg", "Papirus": "22x22/devices/drive-harddisk.svg", "Papirus-Light": "22x22/devices/drive-harddisk.svg", "Adwaita": "symbolic/devices/drive-harddisk-symbolic.svg", "breeze": "devices/22/drive-harddisk-symbolic.svg" },
  "gpu": { "Papirus-Dark": "22x22/apps/utilities-system-monitor.svg", "Papirus": "22x22/apps/utilities-system-monitor.svg", "Papirus-Light": "22x22/apps/utilities-system-monitor.svg" },
  "bat-90": { "Adwaita": "symbolic/status/battery-level-90-symbolic.svg" },
  "notifications-disabled": { "Papirus-Dark": "24x24/panel/notifications-disabled.svg", "Papirus": "24x24/panel/notifications-disabled.svg", "Papirus-Light": "24x24/panel/notifications-disabled.svg", "Adwaita": "symbolic/status/notifications-disabled-symbolic.svg", "breeze": "actions/22/notifications-disabled-symbolic.svg" },
  "bat-40": { "Adwaita": "symbolic/status/battery-level-40-symbolic.svg" },
  "media-play": { "Papirus-Dark": "24x24/actions/media-playback-start.svg", "Papirus": "24x24/actions/media-playback-start.svg", "Papirus-Light": "24x24/actions/media-playback-start.svg", "Adwaita": "symbolic/actions/media-playback-start-symbolic.svg", "breeze": "actions/22/media-playback-start-symbolic.svg" },
  "bat-0": { "Adwaita": "symbolic/status/battery-level-0-symbolic.svg" },
  "bat-50-chg": { "Adwaita": "symbolic/status/battery-level-50-charging-symbolic.svg" },
  "battery-caution": { "Papirus-Dark": "24x24/panel/battery-caution.svg", "Papirus": "24x24/panel/battery-caution.svg", "Papirus-Light": "24x24/panel/battery-caution.svg", "Adwaita": "symbolic/status/battery-caution-symbolic.svg", "breeze": "status/22/battery-caution-symbolic.svg" },
  "sun": { "Papirus-Dark": "24x24/panel/weather-clear.svg", "Papirus": "24x24/panel/weather-clear.svg", "Papirus-Light": "24x24/panel/weather-clear.svg", "Adwaita": "symbolic/status/weather-clear-symbolic.svg" },
  "bat-10-chg": { "Adwaita": "symbolic/status/battery-level-10-charging-symbolic.svg" },
  "mic-low": { "Papirus-Dark": "24x24/panel/microphone-sensitivity-low.svg", "Papirus": "24x24/panel/microphone-sensitivity-low.svg", "Papirus-Light": "24x24/panel/microphone-sensitivity-low.svg", "Adwaita": "symbolic/status/microphone-sensitivity-low-symbolic.svg", "breeze": "status/22/microphone-sensitivity-low-symbolic.svg" },
  "bat-30-chg": { "Adwaita": "symbolic/status/battery-level-30-charging-symbolic.svg" },
  "wifi-off": { "Papirus-Dark": "24x24/panel/network-offline.svg", "Papirus": "24x24/panel/network-offline.svg", "Papirus-Light": "24x24/panel/network-offline.svg", "Adwaita": "symbolic/status/network-offline-symbolic.svg", "breeze": "status/22/network-offline-symbolic.svg" },
  "bat-10": { "Adwaita": "symbolic/status/battery-level-10-symbolic.svg" },
  "wifi-none": { "Papirus-Dark": "24x24/panel/network-wireless-signal-none.svg", "Papirus": "24x24/panel/network-wireless-signal-none.svg", "Papirus-Light": "24x24/panel/network-wireless-signal-none.svg", "Adwaita": "symbolic/status/network-wireless-signal-none-symbolic.svg", "breeze": "status/22/network-wireless-signal-none-symbolic.svg" },
  "audio-volume-low": { "Papirus-Dark": "24x24/panel/audio-volume-low.svg", "Papirus": "24x24/panel/audio-volume-low.svg", "Papirus-Light": "24x24/panel/audio-volume-low.svg", "Adwaita": "symbolic/status/audio-volume-low-symbolic.svg", "breeze": "status/22/audio-volume-low-symbolic.svg" },
  "audio-volume-medium": { "Papirus-Dark": "24x24/panel/audio-volume-medium.svg", "Papirus": "24x24/panel/audio-volume-medium.svg", "Papirus-Light": "24x24/panel/audio-volume-medium.svg", "Adwaita": "symbolic/status/audio-volume-medium-symbolic.svg", "breeze": "status/22/audio-volume-medium-symbolic.svg" },
  "bat-70": { "Adwaita": "symbolic/status/battery-level-70-symbolic.svg" },
  "wallpaper": { "Papirus-Dark": "24x24/apps/preferences-desktop-wallpaper.svg", "Papirus": "24x24/apps/preferences-desktop-wallpaper.svg", "Papirus-Light": "24x24/apps/preferences-desktop-wallpaper.svg", "Adwaita": "symbolic/legacy/preferences-desktop-wallpaper-symbolic.svg" },
  "mic-high": { "Papirus-Dark": "24x24/panel/microphone-sensitivity-high.svg", "Papirus": "24x24/panel/microphone-sensitivity-high.svg", "Papirus-Light": "24x24/panel/microphone-sensitivity-high.svg", "Adwaita": "symbolic/status/microphone-sensitivity-high-symbolic.svg", "breeze": "status/22/microphone-sensitivity-high-symbolic.svg" },
  "wifi-good": { "Papirus-Dark": "24x24/panel/network-wireless-signal-good.svg", "Papirus": "24x24/panel/network-wireless-signal-good.svg", "Papirus-Light": "24x24/panel/network-wireless-signal-good.svg", "Adwaita": "symbolic/status/network-wireless-signal-good-symbolic.svg", "breeze": "status/22/network-wireless-signal-good-symbolic.svg" },
  "pan-up": { "Papirus-Dark": "24x24/actions/pan-up.svg", "Papirus": "24x24/actions/pan-up.svg", "Papirus-Light": "24x24/actions/pan-up.svg", "Adwaita": "symbolic/ui/pan-up-symbolic.svg", "breeze": "actions/16/pan-up-symbolic.svg" },
  "bat-20": { "Adwaita": "symbolic/status/battery-level-20-symbolic.svg" },
  "suspend": { "Papirus-Dark": "24x24/actions/system-suspend.svg", "Papirus": "24x24/actions/system-suspend.svg", "Papirus-Light": "24x24/actions/system-suspend.svg", "breeze": "actions/22/system-suspend-symbolic.svg" },
  "mic-medium": { "Papirus-Dark": "24x24/panel/microphone-sensitivity-medium.svg", "Papirus": "24x24/panel/microphone-sensitivity-medium.svg", "Papirus-Light": "24x24/panel/microphone-sensitivity-medium.svg", "Adwaita": "symbolic/status/microphone-sensitivity-medium-symbolic.svg", "breeze": "status/22/microphone-sensitivity-medium-symbolic.svg" },
  "media-pause": { "Papirus-Dark": "24x24/actions/media-playback-pause.svg", "Papirus": "24x24/actions/media-playback-pause.svg", "Papirus-Light": "24x24/actions/media-playback-pause.svg", "Adwaita": "symbolic/actions/media-playback-pause-symbolic.svg", "breeze": "actions/22/media-playback-pause-symbolic.svg" },
  "bat-80": { "Adwaita": "symbolic/status/battery-level-80-symbolic.svg" },
  "logout": { "Papirus-Dark": "24x24/actions/system-log-out.svg", "Papirus": "24x24/actions/system-log-out.svg", "Papirus-Light": "24x24/actions/system-log-out.svg", "Adwaita": "symbolic/actions/system-log-out-symbolic.svg", "breeze": "actions/22/system-log-out-symbolic.svg" },
  "audio-volume-high": { "Papirus-Dark": "24x24/panel/audio-volume-high.svg", "Papirus": "24x24/panel/audio-volume-high.svg", "Papirus-Light": "24x24/panel/audio-volume-high.svg", "Adwaita": "symbolic/status/audio-volume-high-symbolic.svg", "breeze": "status/22/audio-volume-high-symbolic.svg" },
  "check": { "Papirus-Dark": "24x24/actions/dialog-ok.svg", "Papirus": "24x24/actions/dialog-ok.svg", "Papirus-Light": "24x24/actions/dialog-ok.svg", "breeze": "actions/22/dialog-ok-symbolic.svg" },
  "media-prev": { "Papirus-Dark": "24x24/actions/media-skip-backward.svg", "Papirus": "24x24/actions/media-skip-backward.svg", "Papirus-Light": "24x24/actions/media-skip-backward.svg", "Adwaita": "symbolic/actions/media-skip-backward-symbolic.svg", "breeze": "actions/22/media-skip-backward-symbolic.svg" },
  "search": { "Papirus-Dark": "24x24/actions/system-search.svg", "Papirus": "24x24/actions/system-search.svg", "Papirus-Light": "24x24/actions/system-search.svg", "Adwaita": "symbolic/actions/system-search-symbolic.svg", "breeze": "actions/22/system-search-symbolic.svg" },
  "night": { "Papirus-Dark": "24x24/panel/weather-clear-night.svg", "Papirus": "24x24/panel/weather-clear-night.svg", "Papirus-Light": "24x24/panel/weather-clear-night.svg", "Adwaita": "symbolic/status/weather-clear-night-symbolic.svg" },
  "refresh": { "Papirus-Dark": "24x24/actions/view-refresh.svg", "Papirus": "24x24/actions/view-refresh.svg", "Papirus-Light": "24x24/actions/view-refresh.svg", "Adwaita": "symbolic/actions/view-refresh-symbolic.svg", "breeze": "actions/22/view-refresh-symbolic.svg" },
  "bat-20-chg": { "Adwaita": "symbolic/status/battery-level-20-charging-symbolic.svg" },
  "wifi-ok": { "Papirus-Dark": "24x24/panel/network-wireless-signal-ok.svg", "Papirus": "24x24/panel/network-wireless-signal-ok.svg", "Papirus-Light": "24x24/panel/network-wireless-signal-ok.svg", "Adwaita": "symbolic/status/network-wireless-signal-ok-symbolic.svg", "breeze": "status/22/network-wireless-signal-ok-symbolic.svg" },
  "mic": { "Papirus-Dark": "24x24/devices/audio-input-microphone.svg", "Papirus": "24x24/devices/audio-input-microphone.svg", "Papirus-Light": "24x24/devices/audio-input-microphone.svg", "Adwaita": "symbolic/devices/audio-input-microphone-symbolic.svg", "breeze": "devices/22/audio-input-microphone-symbolic.svg" },
  "bat-50": { "Adwaita": "symbolic/status/battery-level-50-symbolic.svg" },
  "bat-0-chg": { "Adwaita": "symbolic/status/battery-level-0-charging-symbolic.svg" },
  "wifi-excellent": { "Papirus-Dark": "24x24/panel/network-wireless-signal-excellent.svg", "Papirus": "24x24/panel/network-wireless-signal-excellent.svg", "Papirus-Light": "24x24/panel/network-wireless-signal-excellent.svg", "Adwaita": "symbolic/status/network-wireless-signal-excellent-symbolic.svg", "breeze": "status/22/network-wireless-signal-excellent-symbolic.svg" },
  "bat-100": { "Adwaita": "symbolic/status/battery-level-100-symbolic.svg" },
  "bat-80-chg": { "Adwaita": "symbolic/status/battery-level-80-charging-symbolic.svg" },
  "lock": { "Papirus-Dark": "24x24/actions/system-lock-screen.svg", "Papirus": "24x24/actions/system-lock-screen.svg", "Papirus-Light": "24x24/actions/system-lock-screen.svg", "Adwaita": "symbolic/status/system-lock-screen-symbolic.svg", "breeze": "actions/22/system-lock-screen-symbolic.svg" },
  "network-wired": { "Papirus-Dark": "24x24/panel/network-wired.svg", "Papirus": "24x24/panel/network-wired.svg", "Papirus-Light": "24x24/panel/network-wired.svg", "Adwaita": "symbolic/devices/network-wired-symbolic.svg", "breeze": "status/22/network-wired.svg" },
  "pan-down": { "Papirus-Dark": "24x24/actions/pan-down.svg", "Papirus": "24x24/actions/pan-down.svg", "Papirus-Light": "24x24/actions/pan-down.svg", "Adwaita": "symbolic/ui/pan-down-symbolic.svg", "breeze": "actions/16/pan-down-symbolic.svg" },
  "hibernate": { "Papirus-Dark": "24x24/actions/system-suspend-hibernate.svg", "Papirus": "24x24/actions/system-suspend-hibernate.svg", "Papirus-Light": "24x24/actions/system-suspend-hibernate.svg", "breeze": "actions/22/system-suspend-hibernate-symbolic.svg" },
  "bat-60-chg": { "Adwaita": "symbolic/status/battery-level-60-charging-symbolic.svg" },
  "audio-volume-muted": { "Papirus-Dark": "24x24/panel/audio-volume-muted.svg", "Papirus": "24x24/panel/audio-volume-muted.svg", "Papirus-Light": "24x24/panel/audio-volume-muted.svg", "Adwaita": "symbolic/status/audio-volume-muted-symbolic.svg", "breeze": "status/22/audio-volume-muted-symbolic.svg" },
  "bat-70-chg": { "Adwaita": "symbolic/status/battery-level-70-charging-symbolic.svg" },
  "shutdown": { "Papirus-Dark": "24x24/actions/system-shutdown.svg", "Papirus": "24x24/actions/system-shutdown.svg", "Papirus-Light": "24x24/actions/system-shutdown.svg", "Adwaita": "symbolic/actions/system-shutdown-symbolic.svg", "breeze": "actions/22/system-shutdown-symbolic.svg" },
  "bat-charged": { "Adwaita": "symbolic/status/battery-level-100-charged-symbolic.svg" },
  "bat-60": { "Adwaita": "symbolic/status/battery-level-60-symbolic.svg" },
  "notifications": { "Papirus-Dark": "24x24/panel/notifications.svg", "Papirus": "24x24/panel/notifications.svg", "Papirus-Light": "24x24/panel/notifications.svg", "breeze": "actions/22/notifications-symbolic.svg" },
  "media-next": { "Papirus-Dark": "24x24/actions/media-skip-forward.svg", "Papirus": "24x24/actions/media-skip-forward.svg", "Papirus-Light": "24x24/actions/media-skip-forward.svg", "Adwaita": "symbolic/actions/media-skip-forward-symbolic.svg", "breeze": "actions/22/media-skip-forward-symbolic.svg" },
  "mic-muted": { "Papirus-Dark": "24x24/panel/microphone-sensitivity-muted.svg", "Papirus": "24x24/panel/microphone-sensitivity-muted.svg", "Papirus-Light": "24x24/panel/microphone-sensitivity-muted.svg", "Adwaita": "symbolic/status/microphone-sensitivity-muted-symbolic.svg", "breeze": "status/22/microphone-sensitivity-muted-symbolic.svg" },
  "bat-90-chg": { "Adwaita": "symbolic/status/battery-level-90-charging-symbolic.svg" },
  "bat-30": { "Adwaita": "symbolic/status/battery-level-30-symbolic.svg" },
  "bat-40-chg": { "Adwaita": "symbolic/status/battery-level-40-charging-symbolic.svg" },
  "wifi-weak": { "Papirus-Dark": "24x24/panel/network-wireless-signal-weak.svg", "Papirus": "24x24/panel/network-wireless-signal-weak.svg", "Papirus-Light": "24x24/panel/network-wireless-signal-weak.svg", "Adwaita": "symbolic/status/network-wireless-signal-weak-symbolic.svg", "breeze": "status/22/network-wireless-signal-weak-symbolic.svg" },
  "wifi-lock": { "Papirus-Dark": "24x24/actions/dialog-password.svg", "Papirus": "24x24/actions/dialog-password.svg", "Papirus-Light": "24x24/actions/dialog-password.svg", "Adwaita": "symbolic/status/dialog-password-symbolic.svg", "breeze": "status/22/dialog-password.svg" },
};
function pathFor(theme, name) { var m = CATALOG[name]; return m ? (m[theme] || m['Adwaita'] || '') : ''; }

const ROOTS = [
  "/run/current-system/sw/share/icons",
  "/usr/local/share/icons",
  "/usr/share/icons",
]

const INSTALLED = [
  "Papirus-Dark",
  "Papirus",
  "Papirus-Light",
  "Adwaita",
  "breeze",
]

function pushUnique(list, url) {
  for (const u of list)
    if (u === url) return
  list.push(url)
}

function themeFallbackChain(theme) {
  const out = []
  const push = n => { if (n && out.indexOf(n) === -1) out.push(n) }
  push(theme)
  for (const t of INSTALLED) push(t.name)
  push("hicolor")
  return out
}

// Resolve a logical icon name to an ordered list of concrete file URLs.
function resolve(theme, name) {
  const out = []
  for (const t of themeFallbackChain(theme)) {
    const rel = pathFor(t, String(name))
    if (!rel) continue
    for (const root of ROOTS)
      pushUnique(out, root + "/" + t + "/" + rel)
  }
  return out
}
