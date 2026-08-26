import QtQuick
import Quickshell
import Quickshell.Io

Row {
  id: row
  spacing: 8

  property var vals: []

  Text {
    text: row.vals.length > 0 ? "\uF4BC " + row.vals[0] + "%" : ""
    color: "#ffffff"
    font.pixelSize: 12
  }

  Text {
    text: row.vals.length > 1 ? "\uEFC5 " + row.vals[1] + "%" : ""
    color: "#ffffff"
    font.pixelSize: 12
  }

  Process {
    id: watcher
    running: true
    command: ["stdbuf", "-oL", "sh", "-c", "L=\"\"; while :; do C=$(vmstat 1 2 | tail -1 | awk '{print 100-$15}'); M=$(free | awk '/^Mem:/ {printf \"%d\", $3/$2*100}'); V=\"$C $M\"; if [ \"$V\" != \"$L\" ]; then printf '%s\\n' \"$V\"; L=\"$V\"; fi; sleep 2; done"]
    stdout: SplitParser {
      onRead: data => {
        row.vals = data.trim().split(/\s+/)
      }
    }
  }
}
