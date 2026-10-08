pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "WallpaperColors.js" as WC
import "DynamicColor.js" as DynColor

Scope {
  id: root

  readonly property string homeDir: Quickshell.env("HOME")
  readonly property string genDir: homeDir + "/.config/sharkshell"
  readonly property string cfgPath: root.genDir + "/custom-theme.json"
  readonly property string kdePath: root.genDir + "/custom-theme.colors"
  readonly property string qtenginePath: homeDir + "/.config/qtengine/config.json"
  readonly property string kittyPath: root.genDir + "/kitty/kitty-dynamic.conf"
  readonly property string footPath: root.genDir + "/foot/foot-dynamic.ini"
  readonly property string niriPath: root.genDir + "/niri/borders.kdl"
  readonly property string gtk3Ini: homeDir + "/.config/gtk-3.0/settings.ini"
  readonly property string gtk4Ini: homeDir + "/.config/gtk-4.0/settings.ini"
  readonly property string gtk3Css: homeDir + "/.config/gtk-3.0/gtk.css"
  readonly property string gtk4Css: homeDir + "/.config/gtk-4.0/gtk.css"
  readonly property string flatpakPath: homeDir + "/.local/share/flatpak/overrides/global"

  property string bgHex: "#000000"
  property string accentHex: "#3daee9"

  function hslOf(hex, fb) {
    var c = DynColor.toHsl(String(hex || ""))
    if (!c) return fb
    return c
  }

  readonly property real bgH: root.hslOf(root.bgHex, { h: 0, s: 0, l: 0 }).h
  readonly property real bgS: root.hslOf(root.bgHex, { h: 0, s: 0, l: 0 }).s
  readonly property real bgV: root.hslOf(root.bgHex, { h: 0, s: 0, l: 0 }).l
  readonly property real accentH: root.hslOf(root.accentHex, { h: 0.55, s: 0.8, l: 0.55 }).h
  readonly property real accentS: root.hslOf(root.accentHex, { h: 0.55, s: 0.8, l: 0.55 }).s
  readonly property real accentV: root.hslOf(root.accentHex, { h: 0.55, s: 0.8, l: 0.55 }).l

  function setBgH(v) {
    var c = root.hslOf(root.bgHex, { h: 0, s: 0, l: 0 })
    root.bgHex = DynColor.fromHsl(v, c.s, c.l)
    root.saveSoon()
  }
  function setBgS(v) {
    var c = root.hslOf(root.bgHex, { h: 0, s: 0, l: 0 })
    root.bgHex = DynColor.fromHsl(c.h, v, c.l)
    root.saveSoon()
  }
  function setBgV(v) {
    var c = root.hslOf(root.bgHex, { h: 0, s: 0, l: 0 })
    root.bgHex = DynColor.fromHsl(c.h, c.s, v)
    root.saveSoon()
  }
  function setAccentH(v) {
    var c = root.hslOf(root.accentHex, { h: 0.55, s: 0.8, l: 0.55 })
    root.accentHex = DynColor.fromHsl(v, c.s, c.l)
    root.saveSoon()
  }
  function setAccentS(v) {
    var c = root.hslOf(root.accentHex, { h: 0.55, s: 0.8, l: 0.55 })
    root.accentHex = DynColor.fromHsl(c.h, v, c.l)
    root.saveSoon()
  }
  function setAccentV(v) {
    var c = root.hslOf(root.accentHex, { h: 0.55, s: 0.8, l: 0.55 })
    root.accentHex = DynColor.fromHsl(c.h, c.s, v)
    root.saveSoon()
  }

  function autoFg(bg) {
    return DynColor.luminance(bg) < 0.18 ? "#ffffff" : "#000000"
  }

  function rolesFor(dark) {
    var d = (dark === undefined ? DynamicTheme.darkMode : !!dark)
    if (d) {
      var bg = root.bgHex
      return WC.buildCustomRoles(DynColor, bg, root.autoFg(bg), root.accentHex, true)
    }
    var lp = WC.customLightPair(DynColor, root.bgHex, root.accentHex)
    return WC.buildCustomRoles(DynColor, lp.bg, lp.fg, lp.accent, false)
  }

  function kdeTextFor(roles) {
    var prevR = DynamicTheme.roles
    var prevP = DynamicTheme.palettes
    DynamicTheme.roles = roles
    DynamicTheme.palettes = {}
    var out = AppTheme.kdeColorsText()
    DynamicTheme.roles = prevR
    DynamicTheme.palettes = prevP
    return out
  }

  function cssTextFor(roles) {
    var prevR = DynamicTheme.roles
    var prevP = DynamicTheme.palettes
    DynamicTheme.roles = roles
    DynamicTheme.palettes = {}
    var out = AppTheme.gtkCssText()
    DynamicTheme.roles = prevR
    DynamicTheme.palettes = prevP
    return out
  }

  function qtengineJsonText(dark) {
    var d = (dark === undefined ? DynamicTheme.darkMode : !!dark)
    var o = {
      theme: {
        colorScheme: root.kdePath,
        iconTheme: d ? "Papirus-Dark" : "Papirus",
        style: "breeze",
        font: { family: Theme.fontFamily, size: 11, weight: -1 },
        fontFixed: { family: Theme.fontFamily, size: 11, weight: -1 }
      },
      misc: {
        singleClickActivate: false,
        menusHaveIcons: true,
        shortcutsForContextMenus: true
      }
    }
    return JSON.stringify(o)
  }

  function apply() {
    var dark = DynamicTheme.darkMode
    var roles = root.rolesFor(dark)
    DynamicTheme.roles = roles
    DynamicTheme.palettes = {}
    kdeFile.setText(root.kdeTextFor(roles))
    qtFile.setText(root.qtengineJsonText(dark))
    var css = root.cssTextFor(roles)
    cssFile3.setText(css)
    cssFile4.setText(css)
    var ini = AppTheme.settingsIniText("", dark)
    iniFile3.setText(ini)
    iniFile4.setText(ini)
    overridesFile.setText(AppTheme.flatpakOverridesText(dark))
    AppTheme.dconfPush(dark)
    var tc = WC.buildTerminalTheme(DynColor, [], roles, {}, dark)
    kittyFile.setText(DynamicTheme.kittyText(tc))
    footFile.setText(DynamicTheme.footText(tc))
    var prim = roles.primary || "#bbbbbb"
    var high = roles.surface_container_highest || roles.surface_container_high || "#444444"
    niriFile.setText(DynamicTheme.niriText(DynColor.saturate(prim, 0.5) + "ff", high + "ff"))
    if (!kittyProc.running)
      kittyProc.running = true
    if (!niriProc.running)
      niriProc.running = true
    settleTimer.restart()
  }

  function resetDefaults() {
    root.bgHex = "#000000"
    root.accentHex = "#3daee9"
    root.saveSoon()
  }

  function saveSoon() {
    cfgFile.setText(JSON.stringify({ bg: root.bgHex, accent: root.accentHex }) + "\n")
    applyTimer.restart()
  }

  Timer {
    id: applyTimer
    interval: 600
    onTriggered: {
      if (!DynamicTheme.enabled)
        root.apply()
    }
  }

  Process {
    id: kittyProc
    command: ["pkill", "-USR1", "kitty"]
  }

  Process {
    id: niriProc
    command: ["bash", "-c",
      "rt=\"$XDG_RUNTIME_DIR\"; [ -z \"$rt\" ] && rt=\"/run/user/$(id -u)\";"
      + " for s in \"$rt\"/niri.*.sock; do"
      + " [ -S \"$s\" ] || continue;"
      + " NIRI_SOCKET=\"$s\" niri msg action load-config-file >/dev/null 2>&1;"
      + " done; exit 0"]
  }

  Timer {
    id: settleTimer
    interval: 1500
    onTriggered: {
      if (!kittyProc.running)
        kittyProc.running = true
      if (!niriProc.running)
        niriProc.running = true
    }
  }

  FileView {
    id: cfgFile
    path: root.cfgPath
    watchChanges: true
    printErrors: false
    onLoaded: {
      try {
        var o = JSON.parse(text())
        if (o && typeof o.bg === "string" && DynColor.isValid(o.bg)) root.bgHex = String(o.bg).toLowerCase()
        if (o && typeof o.accent === "string" && DynColor.isValid(o.accent)) root.accentHex = String(o.accent).toLowerCase()
      } catch (e) {
      }
    }
    onFileChanged: reload()
  }

  FileView {
    id: kdeFile
    path: root.kdePath
    watchChanges: false
    printErrors: false
  }

  FileView {
    id: qtFile
    path: root.qtenginePath
    watchChanges: false
    printErrors: false
  }

  FileView {
    id: cssFile3
    path: root.gtk3Css
    watchChanges: false
    printErrors: false
  }

  FileView {
    id: cssFile4
    path: root.gtk4Css
    watchChanges: false
    printErrors: false
  }

  FileView {
    id: iniFile3
    path: root.gtk3Ini
    watchChanges: false
    printErrors: false
  }

  FileView {
    id: iniFile4
    path: root.gtk4Ini
    watchChanges: false
    printErrors: false
  }

  FileView {
    id: overridesFile
    path: root.flatpakPath
    watchChanges: false
    printErrors: false
  }

  FileView {
    id: kittyFile
    path: root.kittyPath
    watchChanges: false
    printErrors: false
  }

  FileView {
    id: footFile
    path: root.footPath
    watchChanges: false
    printErrors: false
  }

  FileView {
    id: niriFile
    path: root.niriPath
    watchChanges: false
    printErrors: false
  }

  Process {
    id: mkdirProc
    command: ["bash", "-c",
      "mkdir -p \"$HOME/.config/sharkshell/kitty\" \"$HOME/.config/sharkshell/foot\" \"$HOME/.config/sharkshell/niri\" \"$HOME/.config/qtengine\" \"$HOME/.config/gtk-3.0\" \"$HOME/.config/gtk-4.0\" \"$HOME/.local/share/flatpak/overrides\""]
    onExited: {
      if (!DynamicTheme.enabled)
        root.apply()
    }
  }

  Component.onCompleted: {
    if (!mkdirProc.running)
      mkdirProc.running = true
  }
}
