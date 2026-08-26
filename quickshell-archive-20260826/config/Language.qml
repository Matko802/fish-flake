import QtQuick
import Quickshell
import Quickshell.Io

Text {
  id: langLabel
  text: "?"
  color: "#ffffff"
  font.pixelSize: 12

  Process {
    running: true
    command: ["stdbuf", "-oL", "mmsg", "watch", "keyboardlayout"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const d = JSON.parse(data)
          const name = String(d.layout || "").toLowerCase()
          if (name.startsWith("slovak"))
            langLabel.text = "sk"
          else if (name.startsWith("english"))
            langLabel.text = "us"
          else
            langLabel.text = name.split(/[\s(]/)[0] || "?"
        } catch (e) {}
      }
    }
  }
}
