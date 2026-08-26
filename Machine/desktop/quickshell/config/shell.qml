//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
  id: root
  property bool fullscreenActive: false
  readonly property var _idleRef: IdleManager
  readonly property var _saverRef: ScreenSaver

  Connections {
    target: LockState
    function onLockedChanged() {
      NotificationServer.setDnd(LockState.locked)
    }
  }

  // Track fullscreen immediately via watch (no 250ms poll delay) and
  // keep the bar mapped but put it under the fullscreen app (Background layer)
  // when fullscreen — no visible toggle delay.
  Process {
    id: fsProc
    running: true
    command: ["mmsg", "watch", "focusing-client"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const w = JSON.parse(data)
          root.fullscreenActive = !!(w && w.is_fullscreen)
        } catch (e) {}
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
        WlrLayershell.layer: WlrLayer.Overlay
        // Invisible spacer that keeps 30px exclusive zone even in fullscreen
        // so tiled windows don't resize. Real bar draws only when not fullscreen
        // (or launcher/control open).
        Rectangle {
          anchors.fill: parent
          color: "#000000"
          visible: !root.fullscreenActive || launcher.open || ControlState.open || ClockState.open || emojiPicker.open || clipboard.open
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
    }
  }
  WallpaperPicker {
    id: wallpaperPicker
  }
  PowerMenu {}
  Lock {}
}
