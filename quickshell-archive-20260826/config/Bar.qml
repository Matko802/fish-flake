import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.UPower

Item {
  anchors.fill: parent

  RowLayout {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    spacing: 8

    Workspaces {}
    MangoLayout {}
  }

  ActiveWindow {
    anchors.centerIn: parent
    width: Math.min(300, implicitWidth)
    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
  }

  RowLayout {
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    spacing: 4

    Tray {}
    Language {}

    // clock + notification as one button (right side)
    Rectangle {
      id: clockBtn
      Layout.fillHeight: true
      Layout.topMargin: 4
      Layout.bottomMargin: 4
      implicitWidth: clockRow.implicitWidth + 7
      Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      color: clockMa.containsMouse ? "#ffffff" : "transparent"
      border.color: clockMa.containsMouse ? "#ffffff" : "transparent"
      border.width: 1
      RowLayout {
        id: clockRow
        anchors.left: parent.left
        anchors.leftMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Text {
          id: clockBtnLabel
          color: clockMa.containsMouse ? "#000000" : "#ffffff"
          font.family: Theme.fontFamily
          font.pixelSize: 12
          property int notifCount: NotificationServer.notifications.length
          Timer {
            interval: 1000; running: true; repeat: true; triggeredOnStart: true
            onTriggered: {
              const d = new Date()
              const pad = n => String(n).padStart(2, "0")
              clockBtnLabel.text = pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
            }
          }
        }
        Item {
          Layout.preferredWidth: 18; Layout.preferredHeight: 18
          Text {
            anchors.centerIn: parent
            text: NotificationServer.dnd ? "󰂛" : "󰂚"
            color: clockMa.containsMouse ? "#000000" : "#ffffff"
            font.family: Theme.fontFamily
            font.pixelSize: 12
          }
        }
        Text {
          text: clockBtnLabel.notifCount > 0 ? String(clockBtnLabel.notifCount) : ""
          color: clockMa.containsMouse ? "#000000" : "#ffffff"
          font.family: Theme.fontFamily
          font.pixelSize: 11
          visible: clockBtnLabel.notifCount > 0
          Layout.alignment: Qt.AlignVCenter
        }
      }
      MouseArea {
        id: clockMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ClockState.toggle(clockBtn.QsWindow.window)
      }
    }

    // GNOME-like connected quick-settings button: volume + network + battery
    // Single hover highlight behind all icons.
    Rectangle {
      id: quickSettingsBtn
      Layout.fillHeight: true
      Layout.topMargin: 4
      Layout.bottomMargin: 4
      implicitWidth: quickSettingsRow.implicitWidth + 7
      Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
      radius: 0
      color: quickSettingsMa.containsMouse ? "#ffffff" : "transparent"
      border.color: quickSettingsMa.containsMouse ? "#ffffff" : "transparent"
      border.width: 1

      RowLayout {
        id: quickSettingsRow
        anchors.right: parent.right
        anchors.rightMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Item { Layout.preferredWidth: 18; Layout.preferredHeight: 18; Text { anchors.centerIn: parent; text: Audio.icon; color: quickSettingsMa.containsMouse ? "#000000" : "#ffffff"; font.pixelSize: 12; font.family: Theme.fontFamily } }
        Item { Layout.preferredWidth: 18; Layout.preferredHeight: 18; Text { anchors.centerIn: parent; text: Network.online ? Network.icon : "󰤫"; color: quickSettingsMa.containsMouse ? "#000000" : (Network.online ? "#ffffff" : "#777777"); font.pixelSize: 12; font.family: Theme.fontFamily } }
        Item {
          Layout.preferredWidth: 18; Layout.preferredHeight: 18; visible: batteryText.text !== ""
          Text { id: batteryText; anchors.centerIn: parent; text: {
              try {
                const dev = UPower.displayDevice
                if (!dev || !dev.ready || !dev.isLaptopBattery) return ""
                const p = Math.round(dev.percentage * 100)
                const icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
                let icon
                if (dev.state === UPowerDeviceState.Charging) icon = "󰂄"
                else if (dev.state === UPowerDeviceState.FullyCharged) icon = ""
                else icon = icons[p >= 100 ? 10 : Math.floor(p / 10)]
                return icon
              } catch (e) { return "" }
            }
            color: quickSettingsMa.containsMouse ? "#000000" : "#ffffff"; font.pixelSize: 12; font.family: Theme.fontFamily
          }
        }
      }

      MouseArea {
        id: quickSettingsMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ControlState.toggle(quickSettingsBtn.QsWindow.window)
        onWheel: wheel => {
          if (Audio.vol < 0) return
          Audio.setVol(Audio.vol + (wheel.angleDelta.y > 0 ? 5 : -5))
        }
      }
    }
  }
}
