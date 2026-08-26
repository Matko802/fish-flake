pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: root

  property string path: ""

  FileView {
    id: stateFile

    path: Quickshell.env("HOME") + "/.cache/quickshell-wallpaper"
    watchChanges: false
    printErrors: false
    onLoaded: {
      const p = text().trim()
      if (p !== "")
        root.path = p
    }
  }

  function set(p) {
    root.path = p
    stateFile.setText(p)
  }
}
