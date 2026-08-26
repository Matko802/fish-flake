import QtQuick
import Quickshell
import QtQuick.Layouts

// Presentational toast card. Entrance animation fires only once per instance
// (Component.onCompleted), so it never re-triggers when siblings are added.
Rectangle {
  id: root
  property int notifId: -1
  property string app: ""
  property string appIcon: ""
  property string summary: ""
  property string body: ""
  property int urgency: 1
  property string image: ""
  property string desktopEntry: ""
  property string appName: ""
  property string fontFamily: Theme.fontFamily

  signal closeRequested()
  signal cardClicked()
  signal dismissed()

  color: "#000000"
  radius: 0
  border.color: "#ffffff"
  border.width: 1
  implicitWidth: 340
  implicitHeight: col.implicitHeight + 16

  property bool entered: false
  property bool dismissing: false

  Component.onCompleted: entered = true

  x: (!entered || dismissing) ? 360 : 0
  opacity: dismissing ? 0 : 1
  Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

  onDismissingChanged: if (root.dismissing) dismissTimer.start()
  Timer { id: dismissTimer; interval: 420; repeat: false; onTriggered: root.dismissed() }

  function dismiss() { root.dismissing = true }
  readonly property bool hovered: ma.containsMouse

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
      if (closeMa.containsMouse) return
      if (mouse.button === Qt.RightButton) root.closeRequested()
      else root.cardClicked()
    }
  }

  Column {
    id: col
    spacing: 6
    anchors {
      left: parent.left
      right: parent.right
      top: parent.top
      margins: 8
    }

    RowLayout {
      width: parent.width
      spacing: 8

      Image {
        id: iconImg
        Layout.preferredWidth: 26
        Layout.preferredHeight: 26
        Layout.alignment: Qt.AlignTop
        source: {
          if (root.image && root.image.length > 0) {
            const v = String(root.image)
            if (v.startsWith("file://") || v.startsWith("/")) return v
            if (v.indexOf("://") >= 0) return v
            return Quickshell.iconPath(v, true)
          }
          if (root.appIcon && root.appIcon.length > 0) return Quickshell.iconPath(root.appIcon, true)
          return ""
        }
        visible: status === Image.Ready
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        onStatusChanged: if (status === Image.Error) visible = false
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        RowLayout {
          Layout.fillWidth: true
          Text {
            Layout.fillWidth: true
            text: root.app.toUpperCase()
            color: "#ffffff"
            font.family: root.fontFamily
            font.pixelSize: 10
            font.letterSpacing: 1
            elide: Text.ElideRight
          }
          Rectangle {
            implicitWidth: 18
            implicitHeight: 18
            color: closeMa.containsMouse || closeMa.pressed ? "#ffffff" : "transparent"
            Text {
              anchors.centerIn: parent
              text: "✕"
              color: closeMa.pressed || closeMa.containsMouse ? "#000000" : "#888888"
              font.pixelSize: 11
            }
            MouseArea {
              id: closeMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.closeRequested()
            }
          }
        }

        Text {
          Layout.fillWidth: true
          text: root.summary
          color: "#ffffff"
          font.family: root.fontFamily
          font.pixelSize: 12
          wrapMode: Text.WordWrap
          visible: root.summary.length > 0
        }

        Text {
          Layout.fillWidth: true
          text: root.body
          color: "#cccccc"
          font.family: root.fontFamily
          font.pixelSize: 11
          wrapMode: Text.WordWrap
          visible: root.body.length > 0
        }
      }
    }
  }
}
