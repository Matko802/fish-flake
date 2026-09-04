import QtQuick
import Quickshell
import Quickshell.Io

Text {
  id: layoutLabel
  text: "?"
  color: "#ffffff"
  font.pixelSize: 12
  visible: text !== "" && text !== "niri"

  Process {
    id: detect
    running: true
    command: ["sh", "-c", "command -v niri >/dev/null 2>&1 && niri msg -j workspaces >/dev/null 2>&1 && echo niri || echo mango"]
    stdout: SplitParser {
      onRead: data => {
        if (data.trim() === "niri") {
          layoutLabel.text = ""
          mangoWatch.running = false
        } else {
          mangoWatch.running = true
        }
      }
    }
  }

  Process {
    id: mangoWatch
    running: false
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
