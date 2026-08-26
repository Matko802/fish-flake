import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
  id: root

  // Power menu: grid of tiles in the center of the screen (SUPER+M).
  property bool open: false
  property int selIdx: 0
  property int hoverIdx: -1
  readonly property string fontFamily: Theme.fontFamily
  readonly property int cols: 3
  readonly property int tile: 124

  function requestClose() { root.open = false }
  function forceClose() { root.open = false }

  function toggle() {
    if (root.open) {
      root.requestClose()
      return
    }
    root.open = true
    root.selIdx = 0
    root.hoverIdx = -1
  }

  IpcHandler {
    target: "power"
    function toggle() {
      root.toggle()
    }
    function close() {
      root.forceClose()
    }
  }

  readonly property var entries: [
    { name: "LOCK", icon: "󰌾", cmd: ["quickshell", "ipc", "call", "lock", "lock"] },
    { name: "HIBERNATE", icon: "󰤁", cmd: ["sh", "-c", "loginctl lock-session & sleep 1; systemctl hibernate"] },
    { name: "LOG OUT", icon: "󰍃", cmd: ["mmsg", "dispatch", "quit"] },
    { name: "REBOOT", icon: "󰜉", cmd: ["sh", "-c", "systemctl reboot"] },
    { name: "SHUTDOWN", icon: "󰐥", cmd: ["sh", "-c", "systemctl poweroff"] },
    { name: "SUSPEND", icon: "󰤄", cmd: ["sh", "-c", "loginctl lock-session & sleep 1; systemctl suspend"] }
  ]

  onSelIdxChanged: {
    if (grid)
      grid.positionViewAtIndex(root.selIdx, GridView.Contain)
  }

  function move(step) {
    root.selIdx = Math.max(0, Math.min(root.entries.length - 1, root.selIdx + step))
  }

  function activate(i) {
    const entry = root.entries[i]
    if (!entry)
      return
    root.forceClose()
    runProc.command = entry.cmd
    runProc.running = true
  }

  Process {
    id: runProc
  }

  PanelWindow {
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "#b3000000"
    WlrLayershell.namespace: "quickshell-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    visible: root.open

    MouseArea {
      anchors.fill: parent
      onClicked: root.requestClose()
    }

    GridView {
      id: grid
      anchors.centerIn: parent
      width: root.cols * root.tile
      height: 2 * root.tile
      interactive: false
      focus: true
      cellWidth: root.tile
      cellHeight: root.tile
      model: root.entries

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.requestClose()
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.activate(root.selIdx)
          event.accepted = true
        } else if (event.key === Qt.Key_Left) {
          root.move(-1)
          event.accepted = true
        } else if (event.key === Qt.Key_Right) {
          root.move(1)
          event.accepted = true
        } else if (event.key === Qt.Key_Up) {
          root.move(-root.cols)
          event.accepted = true
        } else if (event.key === Qt.Key_Down) {
          root.move(root.cols)
          event.accepted = true
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_N) {
          root.move(root.cols)
          event.accepted = true
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_P) {
          root.move(-root.cols)
          event.accepted = true
        }
      }

      delegate: Rectangle {
        required property var modelData
        required property int index
        width: grid.cellWidth - 8
        height: grid.cellHeight - 8
        x: 4
        y: 4
        readonly property bool isSel: root.selIdx === index
        readonly property bool isHover: root.hoverIdx === index
        readonly property bool active: isSel || isHover
        color: active ? "#ffffff" : "#000000"
        border.color: "#ffffff"
        border.width: 1

        Column {
          anchors.centerIn: parent
          spacing: 8

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.icon
            color: parent.parent.active ? "#000000" : "#ffffff"
            font.family: root.fontFamily
            font.pixelSize: 34
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.name
            color: parent.parent.active ? "#000000" : "#ffffff"
            font.family: root.fontFamily
            font.pixelSize: 10
            font.letterSpacing: 2
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: { root.hoverIdx = index; root.selIdx = index }
          onExited: { if (root.hoverIdx === index) root.hoverIdx = -1 }
          onClicked: root.activate(index)
        }
      }
    }
  }
}
