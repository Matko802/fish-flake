import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Row {
  spacing: 6

  Repeater {
    model: SystemTray.items

    delegate: Item {
      id: trayItem
      required property var modelData
      property bool wantMenu: false
      width: 18
      height: 18

      Image {
        anchors.centerIn: parent
        source: trayItem.modelData.icon
        width: 16
        height: 16
        sourceSize.width: 16
        sourceSize.height: 16
        fillMode: Image.PreserveAspectFit
      }

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => {
          if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && trayItem.modelData.onlyMenu)) {
            if (!trayItem.modelData.hasMenu)
              return
            trayItem.wantMenu = !trayItem.wantMenu
          } else if (mouse.button === Qt.MiddleButton) {
            trayItem.modelData.secondaryActivate()
          } else {
            trayItem.modelData.activate()
          }
        }
        onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y > 0 ? 1 : -1, false)
      }

      Loader {
        id: menuLoader
        active: trayItem.wantMenu
        sourceComponent: menuComp
        onLoaded: item.open()
        onActiveChanged: {
          if (!active)
            return
        }
      }

      Component {
        id: menuComp
        QsMenuAnchor {
          menu: trayItem.modelData.menu
          anchor.window: trayItem.QsWindow.window
          anchor.item: trayItem
          anchor.edges: Edges.Bottom
          anchor.gravity: Edges.Bottom
        }
      }
    }
  }
}
