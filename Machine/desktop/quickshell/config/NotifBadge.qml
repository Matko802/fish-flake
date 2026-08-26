import QtQuick
import Quickshell

Item {
  id: root
  implicitWidth: label.width + 12
  implicitHeight: 20

  Text {
    id: label
    anchors.centerIn: parent
    property int count: NotificationServer.notifications.length
    text: (NotificationServer.dnd ? "󰂛" : "󰂚") + (count > 0 ? " " + count : "")
    color: "#ffffff"
    font.family: Theme.fontFamily
    font.pixelSize: 12
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
