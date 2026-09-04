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
    spacing: Theme.spacingS

    Workspaces {}
    MangoLayout {}
    ActiveWindow {
      Layout.maximumWidth: 280
      Layout.preferredWidth: 220
      Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easingOut } }
    }
  }

  Rectangle {
    id: clockCenterBtn
    anchors.centerIn: parent
    implicitWidth: clockCenterRow.implicitWidth + 14
    implicitHeight: 22
    color: clockCenterMa.containsMouse ? Theme.fg : "transparent"
    border.color: clockCenterMa.containsMouse ? Theme.outline : "transparent"
    border.width: 1
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easingOut } }
    RowLayout {
      id: clockCenterRow
      anchors.centerIn: parent
      spacing: Theme.spacingS
      Text {
        id: clockCenterLabel
        color: clockCenterMa.containsMouse ? Theme.bg : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 12
        property int notifCount: NotificationServer.meaningfulCount
        Timer {
          interval: 1000; running: true; repeat: true; triggeredOnStart: true
          onTriggered: {
            const d = new Date()
            const pad = n => String(n).padStart(2, "0")
            clockCenterLabel.text = pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
          }
        }
      }
      Item {
        Layout.preferredWidth: 18; Layout.preferredHeight: 18
        visible: clockCenterLabel.notifCount > 0
        QIcon {
          anchors.centerIn: parent
          name: NotificationServer.dnd ? "notifications-disabled" : "notifications"
          size: 18
          color: clockCenterMa.containsMouse ? Theme.bg : Theme.fg
        }
      }
      Text {
        text: clockCenterLabel.notifCount > 0 ? String(clockCenterLabel.notifCount) : ""
        color: clockCenterMa.containsMouse ? Theme.bg : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 11
        visible: clockCenterLabel.notifCount > 0
        Layout.alignment: Qt.AlignVCenter
      }
    }
    MouseArea {
      id: clockCenterMa
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: ClockState.toggle(clockCenterBtn.QsWindow.window)
    }
  }

  RowLayout {
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    spacing: Theme.spacingS

    Tray {}
    Language {}

    // GNOME-like connected quick-settings button: volume + network + battery
    // Single hover highlight behind all icons.
    Rectangle {
      id: quickSettingsBtn
      Layout.fillHeight: true
      Layout.topMargin: 4
      Layout.bottomMargin: 4
      implicitWidth: quickSettingsRow.implicitWidth + 14
      Behavior on implicitWidth { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easingOut } }
      radius: Theme.rounding
      color: quickSettingsMa.containsMouse ? Theme.fg : "transparent"
      border.color: quickSettingsMa.containsMouse ? Theme.outline : "transparent"
      border.width: 1

      RowLayout {
        id: quickSettingsRow
        anchors.centerIn: parent
        spacing: Theme.spacingS

        Item { Layout.preferredWidth: 18; Layout.preferredHeight: 18; QIcon { anchors.centerIn: parent; name: Audio.icon; size: 18; color: quickSettingsMa.containsMouse ? "#000000" : "#ffffff" } }
        Item { Layout.preferredWidth: 18; Layout.preferredHeight: 18; QIcon { anchors.centerIn: parent; name: Network.online ? Network.icon : "wifi-off"; size: 18; color: quickSettingsMa.containsMouse ? "#000000" : (Network.online ? "#ffffff" : "#777777") } }
        Item {
          Layout.preferredWidth: 18; Layout.preferredHeight: 18
          property string batName: {
            try {
              const dev = UPower.displayDevice
              if (!dev || !dev.ready || !dev.isLaptopBattery) return ""
              const p = Math.max(0, Math.min(100, Math.round(dev.percentage * 100)))
              const lv = Math.floor(p / 10) * 10
              if (dev.state === UPowerDeviceState.Charging && lv < 100) return "bat-" + lv + "-chg"
              if (dev.state === UPowerDeviceState.FullyCharged) return "bat-charged"
              return "bat-" + lv
            } catch (e) { return "" }
          }
          visible: batName !== ""
          QIcon { anchors.centerIn: parent; name: parent.batName; size: 18; color: quickSettingsMa.containsMouse ? "#000000" : "#ffffff" }
        }
      }

      MouseArea {
        id: quickSettingsMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ControlState.toggle(quickSettingsBtn.QsWindow.window)
        onWheel: wheel => {
          Audio.setVol((Audio.vol < 0 ? 50 : Audio.vol) + (wheel.angleDelta.y > 0 ? 5 : -5))
        }
      }
    }
  }
}
