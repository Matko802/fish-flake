pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property string fontFamily: Quickshell.env("QUICKSHELL_FONT") || "DepartureMono Nerd Font"

  property string iconTheme: "Tabler"
  readonly property var iconThemes: [
    "Tabler", "Material"
  ]

  FileView {
    id: iconThemeFile

    path: Quickshell.env("HOME") + "/.cache/quickshell-icon-theme"
    watchChanges: false
    printErrors: false
    onLoaded: {
      const v = text().trim()
      if (root.iconThemes.indexOf(v) !== -1)
        root.iconTheme = v
    }
  }

  onIconThemeChanged: {
    iconThemeFile.setText(root.iconTheme)
  }

  readonly property int spacingXS: 4
  readonly property int spacing6: 6
  readonly property int spacingS: 8
  readonly property int spacingM: 12
  readonly property int spacingL: 16
  readonly property int paddingXS: 4
  readonly property int paddingS: 8
  readonly property int paddingM: 12
  readonly property int paddingL: 16
  readonly property int rounding: 0
  readonly property int radius: 0
  readonly property int animFast: 90
  readonly property int animDefault: 140
  readonly property int animSlow: 200
  readonly property int easingOut: Easing.OutCubic
  readonly property int easingIn: Easing.InCubic
  readonly property int easingDefault: Easing.OutCubic
  readonly property color bg: "#000000"
  readonly property color bgAlt: "#0a0a0a"
  readonly property color fg: "#ffffff"
  readonly property color outline: "#ffffff"
  readonly property color border: "#222222"
  readonly property color borderStrong: "#333333"
  readonly property color muted: "#888888"
  readonly property color muted2: "#555555"
  readonly property color muted3: "#333333"
}
