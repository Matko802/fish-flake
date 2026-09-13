//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
  id: root
  property bool barEnabled: true
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
  Process {
    id: niriFsWatch
    running: true
    command: ["sh", "-c", "command -v niri >/dev/null 2>&1 && stdbuf -oL niri msg -j event-stream 2>/dev/null || sleep 999999"]
    stdout: SplitParser {
      onRead: data => {
        if (data.includes("Window") || data.includes("Workspace") || data.includes("Overview") || data.includes("Fullscreen")) {
          if (!niriFsPoll.running) niriFsPoll.running = true
          try {
            const j = JSON.parse(data)
            const w = j.WindowOpenedOrChanged?.window || j.WindowFocusChanged || null
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
        visible: true
        mask: Region { item: root.barShown ? barBg : null }
        WlrLayershell.layer: WlrLayer.Overlay
        Rectangle {
          id: barBg
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
  Variants {
    model: Quickshell.screens
    delegate: Component {
      VolumeOSD {
        required property var modelData
        screen: modelData
      }
    }
  }
  Variants {
    model: Quickshell.screens
    delegate: Component {
      Wallpaper {
        required property var modelData
        screen: modelData
      }
    }
  }
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
