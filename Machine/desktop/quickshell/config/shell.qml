//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
  id: root
  property bool fullscreenActive: false
  readonly property bool barShown: !root.fullscreenActive
    || launcher.open || ControlState.open || ClockState.open
    || emojiPicker.open || clipboard.open
  readonly property var _idleRef: IdleManager

  Connections {
    target: LockState
    function onLockedChanged() {
      NotificationServer.setDnd(LockState.locked)
    }
  }

  // Track fullscreen immediately via watch (instant on focus switch) plus a
  // periodic poll as a safety net, since `mmsg watch focusing-client` only
  // fires on focus *switches* and can miss a window leaving fullscreen while
  // staying focused (leaving fullscreenActive stuck true, hiding the bar).
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

  Process {
    id: fsPoll
    running: false
    command: ["mmsg", "get", "focusing-client"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const w = JSON.parse(data)
          root.fullscreenActive = !!(w && w.is_fullscreen)
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: 500
    running: true
    onTriggered: fsPoll.running = true
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
        // Unmap the whole surface when hidden (fullscreen, nothing open) so it
        // stops capturing pointer input entirely — clicks pass through to the
        // app underneath. It remaps (with the 30px exclusive zone) whenever a
        // menu opens or fullscreen ends.
        visible: root.barShown
        WlrLayershell.layer: WlrLayer.Overlay
        Rectangle {
          anchors.fill: parent
          color: "#000000"
          visible: true
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
    }
  }
  WallpaperPicker {
    id: wallpaperPicker
  }
  PowerMenu {}
  Lock {}
}
