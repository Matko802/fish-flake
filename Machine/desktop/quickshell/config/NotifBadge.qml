import QtQuick
import Quickshell

Item {
  id: root
  implicitWidth: row.width + 12
  implicitHeight: 20

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 3
    QIcon {
      id: bell
      anchors.verticalCenter: parent.verticalCenter
      name: NotificationServer.dnd ? "notifications-disabled" : "notifications"
      size: 14
      color: "#ffffff"
    }
    Text {
      id: label
      anchors.verticalCenter: parent.verticalCenter
      property int count: NotificationServer.meaningfulCount
      text: count > 0 ? String(count) : ""
      color: "#ffffff"
      font.family: Theme.fontFamily
      font.pixelSize: 12
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
      // Open the control-center on this screen (where notifications history lives).
      const win = root.QsWindow ? root.QsWindow.window : null
      ControlState.toggle(win)
    }
    onWheel: wheel => {
      if (wheel.angleDelta.y < 0)
        NotificationServer.toggleDnd()
    }
  }
}
