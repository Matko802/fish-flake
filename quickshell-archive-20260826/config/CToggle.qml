import QtQuick

Rectangle {
  id: root

  property bool checked: false
  signal toggled(bool checked)

  implicitWidth: 32
  implicitHeight: 16
  radius: 0
  color: checked ? "#ffffff" : "#000000"
  border.color: "#ffffff"
  border.width: 1

  Behavior on color {
    ColorAnimation {
      duration: 120
    }
  }

  Rectangle {
    x: root.checked ? parent.width - width - 2 : 2
    anchors.verticalCenter: parent.verticalCenter
    width: 12
    height: 12
    radius: 0
    color: root.checked ? "#000000" : "#ffffff"

    Behavior on x {
      NumberAnimation {
        duration: 120
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled(!root.checked)
  }
}
