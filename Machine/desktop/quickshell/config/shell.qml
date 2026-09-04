//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
  id: root
  // Top bar visible, hidden only in fullscreen (menus pop above on Overlay)
  property bool barEnabled: true
  // True when a fullscreen app covers the screen (bar hides)
  property bool fullscreenActive: false
  readonly property bool barShown: barEnabled && (!root.fullscreenActive
    || launcher.open || ControlState.open || ClockState.open
    || emojiPicker.open || clipboard.open)

  IpcHandler {
    target: "bar"
    function toggle(): void { root.barEnabled = !root.barEnabled }
    function show(): void { root.barEnabled = true }
    function hide(): void { root.barEnabled = false }
  }

  Connections {
    target: LockState
    function onLockedChanged() {
      NotificationServer.setDnd(LockState.locked)
    }
  }

  // Niri fullscreen detection: focused window covering output size → hide bar.
  // Responsive: event-stream triggers instant poll + fast 100ms fallback.
  function applyFs(d) {
    if (!d || !d.layout) { root.fullscreenActive = false; return }
    const ws = d.layout.window_size
    const ts = d.layout.tile_size
    const ow = Quickshell.screens.length > 0 ? Math.round(Quickshell.screens[0].width) : 1920
    const oh = Quickshell.screens.length > 0 ? Math.round(Quickshell.screens[0].height) : 1080
    const wFs = ws && Math.round(ws[0]) === ow && Math.round(ws[1]) === oh
    const tFs = ts && Math.round(ts[0]) === ow && Math.round(ts[1]) === oh
    root.fullscreenActive = wFs || tFs
  }
  Process {
    id: niriFsPoll
    running: false
    command: ["/run/current-system/sw/bin/niri", "msg", "-j", "focused-window"]
    stdout: StdioCollector {
      onStreamFinished: {
        try { applyFs(JSON.parse(text.trim())) } catch (e) {
          const ow = Quickshell.screens.length > 0 ? Math.round(Quickshell.screens[0].width) : 1920
          const oh = Quickshell.screens.length > 0 ? Math.round(Quickshell.screens[0].height) : 1080
          const pat1 = "[" + ow + "," + oh + "]"
          const pat2 = "[" + ow + ".0," + oh + ".0]"
          const pat3 = "[" + ow + ", " + oh + "]"
          const pat4 = "[" + ow + ".0, " + oh + ".0]"
          root.fullscreenActive = text.includes(pat1) || text.includes(pat2) || text.includes(pat3) || text.includes(pat4)
        }
      }
    }
  }
  // Instant trigger on any window/workspace focus change
  Process {
    id: niriFsWatch
    running: true
    command: ["sh", "-c", "command -v niri >/dev/null 2>&1 && stdbuf -oL niri msg -j event-stream 2>/dev/null || sleep 999999"]
    stdout: SplitParser {
      onRead: data => {
        if (data.includes("Window") || data.includes("Workspace") || data.includes("Overview") || data.includes("Fullscreen")) {
          if (!niriFsPoll.running) niriFsPoll.running = true
          // Fast path: try to apply without extra round-trip when payload contains focused window
          try {
            const j = JSON.parse(data)
            const w = j.WindowOpenedOrChanged?.window || j.WindowFocusChanged || null
            // WindowFocusChanged is just {id: N}, need full data -> fallback to poll, so ignore
            // WindowsChanged contains array, extract focused directly
            const wins = j.WindowsChanged?.windows
            if (wins) {
              const f = wins.find(x => x.is_focused)
              if (f) applyFs(f)
            } else if (j.WindowOpenedOrChanged?.window?.is_focused) {
              applyFs(j.WindowOpenedOrChanged.window)
            }
          } catch (e) {}
        }
      }
    }
  }
  Timer { interval: 100; running: true; repeat: true; triggeredOnStart: true; onTriggered: { if (!niriFsPoll.running) niriFsPoll.running = true } }

  Variants {
    model: Quickshell.screens
    delegate: Component {
      PanelWindow {
        id: barWindow
        required property var modelData
        screen: modelData
        anchors.top: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 30
        color: "transparent"
        exclusionMode: ExclusionMode.Auto
        WlrLayershell.namespace: "quickshell"
        // Always mapped to reserve 30px strut even when bar is hidden (fullscreen).
        // Inner bar content is hidden via `barShown`, but the exclusive zone remains
        // so tiled windows stay inset and don't jump. True fullscreen (`fullscreen-window`)
        // still bypasses the strut and covers the area.
        visible: true
        WlrLayershell.layer: WlrLayer.Overlay
        Rectangle {
          anchors.fill: parent
          color: "#000000"
          opacity: root.barShown ? 1 : 0
          visible: opacity > 0.01
          Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easingOut } }
          Bar { anchors.fill: parent }
        }
        ControlCenter {
          targetScreen: modelData
        }
        ControlCenterCard {
          targetScreen: modelData
        }
        ClockMenu {
          targetScreen: modelData
        }
      }
    }
  }

  ToastStack {}
  VolumeOSD {}
  ScreensharePicker {}
  Wallpaper {}
  Launcher {
    id: launcher
    onOpenChanged: if (open) { emojiPicker.requestClose(); clipboard.requestClose() }
  }
  EmojiPicker {
    id: emojiPicker
    onOpenChanged: if (open) { launcher.requestClose(); clipboard.requestClose() }
  }
  Clipboard {
    id: clipboard
    onOpenChanged: if (open) { launcher.requestClose(); emojiPicker.requestClose() }
  }
  SettingsMenu {
    id: settingsMenu
    onChoose: action => {
      if (action === "wallpaper")
        wallpaperPicker.toggle()
      else if (action === "launcher")
        launcher.toggle()
      else if (action === "avatar")
        avatarPicker.toggle()
    }
  }
  WallpaperPicker {
    id: wallpaperPicker
  }
  AvatarPicker {
    id: avatarPicker
  }
  PowerMenu {}
  Lock {}
}
