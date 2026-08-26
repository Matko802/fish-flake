pragma Singleton
import Quickshell

Singleton {
  // Font follows system `custom.fontName` via QUICKSHELL_FONT env (set in Nix).
  // Change `custom.fontName` in your host config and rebuild — no QML hardcode.
  property string fontFamily: Quickshell.env("QUICKSHELL_FONT") || "DepartureMono Nerd Font"
}
