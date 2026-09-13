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
    watchChanges: true
    printErrors: false
    onLoaded: {
      const p = text().trim()
      if (p !== "")
        root.path = p
    }
    onFileChanged: reload()
  }

  function set(p) {
    root.path = p
    stateFile.setText(p)
  }
}
