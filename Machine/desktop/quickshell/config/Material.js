.pragma library

// Google Material Icons registry (MaterialIcons-Regular.ttf).
// Maps the shell's logical icon names to the authoritative Material Icons
// PUA codepoints from google/material-design-icons font/.codepoints.
const CODEPOINTS = {
  "arrow-up": 0xE5D8,
  "camera-photo": 0xE3B0,
  "folder": 0xE2C7,
  "folder-open": 0xE2C8,
  "file": 0xE873,
  "file-image": 0xE3F4,
  "file-video": 0xE02C,
  "file-audio": 0xEB82,
  "file-archive": 0xE149,
  "go-next": 0xE5C8,
  "home": 0xE88A,
  "chevron-left": 0xE5CB,
  "chevron-right": 0xE5CC,
  "lock": 0xE897,
  "settings": 0xE8B8,
  "preferences-system": 0xE8B8,
  "preferences-desktop-theme": 0xE40A,
  "player-skip-back": 0xE045,
  "player-skip-forward": 0xE044,
  "refresh": 0xE5D5,
  "search": 0xE8B6,
  "wallpaper": 0xE1BC,
  "cpu": 0xE322,
  "database": 0xE1DB,
  "device-desktop": 0xE30A,
  "user-circle": 0xE853,
  "pan-up": 0xE5CE,
  "pan-down": 0xE5CF,
  "check": 0xE5CA,
  "coffee": 0xEFEF,
  "coffee-off": 0xEFEF,
  "notifications": 0xE7F4,
  "notifications-disabled": 0xE7F6,
  "player-play": 0xE037,
  "player-pause": 0xE034,
  "audio-volume-muted": 0xE04F,
  "audio-volume-low": 0xE04D,
  "audio-volume-medium": 0xE04D,
  "audio-volume-high": 0xE050,
  "mic": 0xE029,
  "mic-muted": 0xE02B,
  "wifi-none": 0xF0B0,
  "wifi-weak": 0xE4CA,
  "wifi-ok": 0xE4D9,
  "wifi-good": 0xE4D9,
  "wifi-excellent": 0xE1D8,
  "wifi-off": 0xE648,
  "wifi-lock": 0xE899,
  "network-wired": 0xE8BE,
  "bat-0": 0xEBDC,
  "bat-0-chg": 0xE1A3,
  "bat-10": 0xEBD9,
  "bat-10-chg": 0xE1A3,
  "bat-20": 0xEBE0,
  "bat-20-chg": 0xE1A3,
  "bat-30": 0xEBDD,
  "bat-30-chg": 0xE1A3,
  "bat-40": 0xEBE2,
  "bat-40-chg": 0xE1A3,
  "bat-50": 0xEBD4,
  "bat-50-chg": 0xE1A3,
  "bat-60": 0xEBD2,
  "bat-60-chg": 0xE1A3,
  "bat-70": 0xEBD2,
  "bat-70-chg": 0xE1A3,
  "bat-80": 0xEBD2,
  "bat-80-chg": 0xE1A3,
  "bat-90": 0xEBD2,
  "bat-90-chg": 0xE1A3,
  "bat-100": 0xE1A4,
  "bat-100-chg": 0xE1A3,
  "bat-charged": 0xE1A3,
  "bat-caution": 0xE19C,
  "logout": 0xE9BA,
  "reboot": 0xF053,
  "shutdown": 0xE8AC,
  "suspend": 0xEF44,
  "hibernate": 0xF03D,
};

function resolve(name) {
  const cp = CODEPOINTS[String(name)];
  if (cp) return String.fromCodePoint(cp);
  return "";
}

function has(name) {
  return !!CODEPOINTS[String(name)];
}

const OUTLINED = {
  "coffee-off": true,
};

function isOutlined(name) {
  return !!OUTLINED[String(name)];
}
