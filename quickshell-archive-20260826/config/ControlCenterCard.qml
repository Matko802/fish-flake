import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire

PanelWindow {
  id: ccCard

  property var targetScreen: null
  property string pwFor: ""
  property bool appsExpanded: false

  PwObjectTracker {
    objects: Pipewire.nodes.values.filter(n => n && n.isStream && n.audio && n.isSink)
  }

  anchors.top: true
  anchors.right: true
  margins.top: 38
  margins.right: 8
  implicitWidth: 356
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"
  WlrLayershell.namespace: "quickshell"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  property bool shown: false
  screen: ccCard.targetScreen
  visible: ccCard.shown && (!ControlState.screen || ControlState.screen === ccCard.targetScreen)
  implicitHeight: col.implicitHeight + 28

  Process { id: focusProc; running: false }
  function focusApp(n) {
    const raw = n ? (n.desktopEntry || n.appName || "") : ""
    if (!raw) return
    const cmd = 'app="' + String(raw).replace(/"/g, '\\"') + '"; id=$(mmsg get all-clients 2>/dev/null | python3 -c "import json,sys; app=sys.argv[1].lower(); data=json.load(sys.stdin); cs=data.get(\'clients\',[]); m=[c for c in cs if app==c.get(\'appid\',\'\').lower() or app in c.get(\'appid\',\'\').lower() or app in c.get(\'title\',\'\').lower()]; print(m[0][\'id\'] if m else \'\')" "$app" 2>/dev/null); [ -n "$id" ] && mmsg dispatch focusid client,$id 2>/dev/null || true'
    focusProc.command = ["bash", "-c", cmd]
    focusProc.running = true
  }

  Connections {
    target: ControlState
    function onOpenChanged() {
      if (ControlState.open && (!ControlState.screen || ControlState.screen === ccCard.targetScreen))
        ccCard.shown = true
      else if (!ControlState.open && ccCard.shown && slideOut.running === false)
        slideOut.restart()
    }
  }

  onShownChanged: {
    if (shown) {
      card.y = -card.height - 8
      slideIn.restart()
    }
  }

  NumberAnimation {
    id: slideIn
    target: card
    property: "y"
    to: 0
    duration: 260
    easing.type: Easing.OutCubic
  }

  NumberAnimation {
    id: slideOut
    target: card
    property: "y"
    to: -ccCard.height - 8
    duration: 200
    easing.type: Easing.InCubic
    onFinished: ccCard.shown = false
  }

  function submitPw() {
    if (ccCard.pwFor === "")
      return
    Network.connectTo(ccCard.pwFor, pwInput.text)
    ccCard.pwFor = ""
  }

  Timer {
    running: Network.expanded && Network.wifiEnabled && ccCard.visible
    interval: 15000
    repeat: true
    onTriggered: Network.scan()
  }

  Rectangle {
    id: card
    width: parent.width
    height: parent.height
    radius: 0
    color: "#000000"
    border.color: "#ffffff"
    border.width: 1

    MouseArea {
      anchors.fill: parent
    }

    ColumnLayout {
      id: col
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 14
      spacing: 12

        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Quick Settings"
            color: "#ffffff"
            font.pixelSize: 12
            font.letterSpacing: 1
          }
          Item {
            Layout.fillWidth: true
          }
        }

      RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
          text: Audio.icon
          color: "#ffffff"
          font.pixelSize: 16
          font.family: Theme.fontFamily
          Layout.preferredWidth: 20
          Layout.minimumWidth: 20
          Layout.maximumWidth: 20
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Audio.toggleMute()
          }
        }
        CSlider {
          id: volSlider
          Layout.fillWidth: true
          value: Audio.vol < 0 ? 0 : Audio.vol / 100
          onUserSet: v => Audio.setVol(v * 100)
        }
        Text {
          text: Math.round(volSlider.shown * 100) + "%"
          color: "#ffffff"
          font.pixelSize: 11
          Layout.preferredWidth: 40
          Layout.minimumWidth: 40
          Layout.maximumWidth: 40
          horizontalAlignment: Text.AlignRight
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
          text: Audio.micIcon
          color: "#ffffff"
          font.pixelSize: 16
          font.family: Theme.fontFamily
          Layout.preferredWidth: 20
          Layout.minimumWidth: 20
          Layout.maximumWidth: 20
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Audio.toggleMicMute()
          }
        }
        CSlider {
          id: micSlider
          Layout.fillWidth: true
          value: Audio.micVol < 0 ? 0 : Audio.micVol / 100
          onUserSet: v => Audio.setMicVol(v * 100)
        }
        Text {
          text: Math.round(micSlider.shown * 100) + "%"
          color: "#ffffff"
          font.pixelSize: 11
          Layout.preferredWidth: 40
          Layout.minimumWidth: 40
          Layout.maximumWidth: 40
          horizontalAlignment: Text.AlignRight
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
          text: "Apps"
          color: "#888888"
          font.pixelSize: 10
          font.letterSpacing: 1
          Layout.alignment: Qt.AlignVCenter
        }
        Item { Layout.fillWidth: true }
        Rectangle {
          implicitWidth: 18
          implicitHeight: 18
          radius: 0
          color: appsExpMa.containsMouse || appsExpMa.pressed ? "#ffffff" : "transparent"
          Text {
            anchors.centerIn: parent
            text: ccCard.appsExpanded ? "" : ""
            color: appsExpMa.pressed ? "#000000" : (appsExpMa.containsMouse ? "#000000" : "#ffffff")
            font.pixelSize: 12
          }
          MouseArea {
            id: appsExpMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ccCard.appsExpanded = !ccCard.appsExpanded
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        visible: ccCard.appsExpanded
        spacing: 6
        Repeater {
          model: Pipewire.nodes.values.filter(n => n && n.isStream && n.audio && n.isSink)
          delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 8
            Text {
              Layout.fillWidth: true
              Layout.maximumWidth: 110
              text: {
                const p = modelData.properties || {}
                return (p["application.name"] || modelData.description || modelData.name || "app").toString().slice(0, 22)
              }
              color: "#ffffff"
              font.pixelSize: 10
              elide: Text.ElideRight
            }
            Text {
              text: modelData.audio && modelData.audio.muted ? "󰝟" : "󰕾"
              color: "#ffffff"
              font.family: Theme.fontFamily
              font.pixelSize: 12
              Layout.preferredWidth: 16
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (modelData.audio) modelData.audio.muted = !modelData.audio.muted
              }
            }
            CSlider {
              Layout.fillWidth: true
              value: modelData.audio ? modelData.audio.volume : 0
              onUserSet: v => { if (modelData.audio) modelData.audio.volume = Math.max(0, Math.min(1.5, v)) }
            }
            Text {
              text: modelData.audio ? Math.round(modelData.audio.volume * 100) + "%" : "—"
              color: "#ffffff"
              font.pixelSize: 10
              Layout.preferredWidth: 32
              horizontalAlignment: Text.AlignRight
            }
          }
        }
        Text {
          Layout.fillWidth: true
          text: Pipewire.nodes.values.filter(n => n && n.isStream && n.audio && n.isSink).length === 0 ? "no apps playing" : ""
          color: "#666666"
          font.pixelSize: 10
          visible: Pipewire.nodes.values.filter(n => n && n.isStream && n.audio && n.isSink).length === 0
          horizontalAlignment: Text.AlignHCenter
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: "#333333"
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
          text: Network.online ? Network.icon : "󰤫"
          color: Network.online ? "#ffffff" : "#777777"
          font.pixelSize: 15
          font.family: Theme.fontFamily
          Layout.preferredWidth: 20
          Layout.minimumWidth: 20
          Layout.maximumWidth: 20
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
        }
        Text {
          text: Network.kind === "wifi" ? Network.ssid : (Network.kind === "eth" ? "Ethernet" : (Network.wifiEnabled ? "Wi-Fi on" : "Wi-Fi off"))
          color: Network.online ? "#ffffff" : "#777777"
          font.pixelSize: 12
          elide: Text.ElideRight
          Layout.maximumWidth: 220
          Layout.fillWidth: true
        }
        Item {
          Layout.fillWidth: true
        }
        CToggle {
          checked: Network.wifiEnabled
          onToggled: c => Network.toggleWifi()
        }
        Rectangle {
          implicitWidth: 18
          implicitHeight: 18
          radius: 0
          color: expMa.containsMouse || expMa.pressed ? "#ffffff" : "transparent"
          Text {
            anchors.centerIn: parent
            text: Network.expanded ? "" : ""
            color: expMa.pressed ? "#000000" : (expMa.containsMouse ? "#000000" : "#ffffff")
            font.pixelSize: 12
          }
          MouseArea {
            id: expMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Network.expanded = !Network.expanded
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        visible: Network.expanded && Network.wifiEnabled
        spacing: 6

        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "Networks"
            color: "#888888"
            font.pixelSize: 10
            font.letterSpacing: 1
          }
          Text {
            text: Network.connecting !== "" ? "connecting to " + Network.connecting + "…" : (Network.scanning ? "scanning…" : "")
            color: "#888888"
            font.pixelSize: 10
            Layout.leftMargin: 6
          }
          Item {
            Layout.fillWidth: true
          }
          Text {
            text: Network.lastError
            color: "#ff7777"
            font.pixelSize: 10
            visible: Network.lastError !== ""
          }
          Rectangle {
            implicitWidth: 18
            implicitHeight: 18
            radius: 0
            color: rescanMa.containsMouse || rescanMa.pressed ? "#ffffff" : "transparent"
            border.color: "#ffffff"
            border.width: 1
            Text {
              anchors.centerIn: parent
              text: ""
              color: rescanMa.pressed ? "#000000" : "#ffffff"
              font.pixelSize: 11
            }
            MouseArea {
              id: rescanMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Network.scan()
            }
          }
        }

        ColumnLayout {
          visible: ccCard.pwFor !== ""
          Layout.fillWidth: true
          spacing: 4
          Text {
            text: "password for " + ccCard.pwFor
            color: "#ffffff"
            font.pixelSize: 10
          }
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 22
            radius: 0
            color: "#000000"
            border.color: "#ffffff"
            border.width: 1
            TextInput {
              id: pwInput
              anchors.fill: parent
              anchors.margins: 4
              echoMode: TextInput.Password
              color: "#ffffff"
              font.pixelSize: 11
              clip: true
              onVisibleChanged: {
                if (visible)
                  forceActiveFocus()
              }
              Keys.onReturnPressed: ccCard.submitPw()
              Keys.onEnterPressed: ccCard.submitPw()
              Keys.onEscapePressed: {
                ccCard.pwFor = ""
                text = ""
              }
            }
          }
          RowLayout {
            spacing: 6
            layoutDirection: Qt.RightToLeft
            Rectangle {
              implicitWidth: 54
              implicitHeight: 20
              radius: 0
              color: pwOkMa.pressed ? "#ffffff" : "#000000"
              border.color: "#ffffff"
              border.width: 1
              Text {
                anchors.centerIn: parent
                text: "connect"
                color: pwOkMa.pressed ? "#000000" : "#ffffff"
                font.pixelSize: 9
              }
              MouseArea {
                id: pwOkMa
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ccCard.submitPw()
              }
            }
            Rectangle {
              implicitWidth: 48
              implicitHeight: 20
              radius: 0
              color: pwNoMa.pressed ? "#ffffff" : "#000000"
              border.color: "#ffffff"
              border.width: 1
              Text {
                anchors.centerIn: parent
                text: "cancel"
                color: pwNoMa.pressed ? "#000000" : "#ffffff"
                font.pixelSize: 9
              }
              MouseArea {
                id: pwNoMa
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  ccCard.pwFor = ""
                  pwInput.text = ""
                }
              }
            }
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: Math.min(netCol.height, 170)
          clip: true
          ColumnLayout {
            id: netCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 3
            Repeater {
              model: Network.networks
              delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8
                height: 20
                Text {
                  text: Network.sigIcon(modelData.sig)
                  color: modelData.active ? "#ffffff" : "#aaaaaa"
                  font.pixelSize: 13
                }
                Text {
                  text: modelData.ssid
                  color: modelData.active ? "#ffffff" : "#cccccc"
                  font.pixelSize: 11
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }
                Text {
                  text: modelData.active ? "" : (modelData.secure ? "" : "")
                  color: modelData.active ? "#ffffff" : "#777777"
                  font.pixelSize: 10
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (Network.connecting !== "" || modelData.active)
                      return
                    if (modelData.secure) {
                      ccCard.pwFor = modelData.ssid
                      pwInput.text = ""
                    } else {
                      Network.connectTo(modelData.ssid, "")
                    }
                  }
                }
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: "#333333"
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
          text: NotificationServer.dnd ? "󰂛" : "󰂚"
          color: "#ffffff"
          font.pixelSize: 15
          font.family: Theme.fontFamily
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: NotificationServer.setDnd(!NotificationServer.dnd)
          }
        }
        Text {
          text: "󰌾"
          color: "#ffffff"
          font.pixelSize: 15
          font.family: Theme.fontFamily
          MouseArea {
            id: lockMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              ControlState.close()
              LockState.locked = true
            }
          }
        }
        Item { Layout.fillWidth: true }
      }
    }
  }
}
