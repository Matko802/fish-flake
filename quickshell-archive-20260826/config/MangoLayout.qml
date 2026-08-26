import QtQuick
import Quickshell
import Quickshell.Io

Text {
  id: layoutLabel
  text: "?"
  color: "#ffffff"
  font.pixelSize: 12

  Process {
    running: true
    command: ["stdbuf", "-oL", "mmsg", "watch", "all-monitors"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const d = JSON.parse(data)
          const m = d.monitors && d.monitors[0]
          if (m && m.layout_symbol)
            layoutLabel.text = m.layout_symbol
        } catch (e) {}
      }
    }
  }
}
