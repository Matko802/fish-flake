import QtQuick
import Quickshell

Text {
  id: clockLabel
  text: ""
  color: "#ffffff"
  font.pixelSize: 12

  MouseArea {
    id: ma
    anchors.fill: parent
    anchors.margins: -6
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: ClockState.toggle(clockLabel.QsWindow.window)
  }

  opacity: ma.containsMouse ? 0.7 : 1

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      const d = new Date()
      const pad = n => String(n).padStart(2, "0")
      clockLabel.text = pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
    }
  }
}
