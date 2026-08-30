pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: root

  property bool open: false
  property var screen: null

  IpcHandler {
    target: "clock"
    function toggle(): void { root.open = !root.open }
    function open(): void { root.open = true }
    function close(): void { root.open = false }
  }

  function toggle(win) {
    const s = win ? win.screen : null
    if (root.open && root.screen === s)
      root.open = false
    else {
      root.screen = s
      root.open = true
      ControlState.close()
    }
  }

  function close() {
    root.open = false
  }
}
