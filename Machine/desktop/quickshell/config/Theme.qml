pragma Singleton
import QtQuick
import Quickshell

Singleton {
  // Font follows system `custom.fontName` via QUICKSHELL_FONT env (set in Nix).
  property string fontFamily: Quickshell.env("QUICKSHELL_FONT") || "DepartureMono Nerd Font"

  // Tokens — sharp monochrome, inspired by Caelestia Tokens
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
  readonly property int animFast: 180
  readonly property int animDefault: 260
  readonly property int animSlow: 320
  // easing
  readonly property int easingOut: Easing.OutCubic
  readonly property int easingIn: Easing.InCubic
  readonly property int easingDefault: Easing.OutCubic
  // colors
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
