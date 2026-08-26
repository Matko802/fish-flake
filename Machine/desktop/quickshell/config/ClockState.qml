pragma Singleton
import QtQuick
import Quickshell

Scope {
  id: root

  property bool open: false
  property var screen: null

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
