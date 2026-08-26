import QtQuick
import Quickshell
import Quickshell.Io

Row {
  spacing: 4

  Repeater {
    id: repeater
    model: []
    property string lastJson: ""
    delegate: Rectangle {
      width: 20
      height: 20
      color: modelData.urgent ? "#ff0000" : (modelData.active ? "#ffffff" : "transparent")
      border.width: 0

      Text {
        anchors.centerIn: parent
        text: modelData.index
        color: modelData.urgent || modelData.active ? "#000000" : "#888888"
        font.pixelSize: 11
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
          if (mouse.button === Qt.RightButton)
            Quickshell.execDetached(["mmsg", "dispatch", "toggle," + modelData.index])
          else
            Quickshell.execDetached(["mmsg", "dispatch", "view," + modelData.index + ",0"])
        }
      }
    }
  }

  Process {
    running: true
    command: ["stdbuf", "-oL", "mmsg", "watch", "all-tags"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const d = JSON.parse(data)
          const groups = d.all_tags || []
          const arr = groups.length ? (groups[0].tags || []) : []
          const next = arr
            .filter(t => t.is_active || (t.client_count || 0) > 0 || !!t.is_urgent)
            .map(t => ({
              index: t.index,
              active: !!t.is_active,
              occupied: (t.client_count || 0) > 0,
              urgent: !!t.is_urgent
            }))
          const json = JSON.stringify(next)
          if (json !== repeater.lastJson) {
            repeater.lastJson = json
            repeater.model = next
          }
        } catch (e) {}
      }
    }
  }
}
