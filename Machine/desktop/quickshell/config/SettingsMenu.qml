import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
  id: root

  signal choose(string action)

  property bool open: false
  property string query: ""
  property int selIdx: 0
  property int hoverIdx: -1
  readonly property string fontFamily: Theme.fontFamily
  readonly property int cellW: 140
  readonly property int cellH: 56

  property bool closePending: false

  function requestClose() {
    if (!root.open || root.closePending)
      return
    root.closePending = true
    closeTimer.restart()
  }

  function forceClose() {
    closeTimer.stop()
    root.closePending = false
    root.open = false
  }

  Timer {
    id: closeTimer
    interval: 250
    onTriggered: {
      root.open = false
      closeCleanTimer.restart()
    }
  }

  Timer {
    id: closeCleanTimer
    interval: 250
    onTriggered: {
      root.closePending = false
    }
  }

  function toggle() {
    if (root.open) {
      root.requestClose()
      return
    }
    closeTimer.stop()
    root.closePending = false
    root.open = true
    root.query = ""
    root.selIdx = 0
    root.hoverIdx = -1
  }

  IpcHandler {
    target: "settings"
    function toggle() {
      root.toggle()
    }
    function close() {
      root.forceClose()
    }
  }

  readonly property var menuEntries: [
    { name: "Wallpaper", glyph: "󰀾", action: "wallpaper" },
    { name: "Launcher", glyph: "󰍉", action: "launcher" }
  ]

  readonly property var results: {
    const q = root.query.toLowerCase()
    if (q === "")
      return menuEntries
    return menuEntries.filter(e => e.name.toLowerCase().includes(q))
  }

  onQueryChanged: {
    root.selIdx = 0
    root.hoverIdx = -1
  }
  onResultsChanged: {
    if (root.selIdx >= root.results.length)
      root.selIdx = Math.max(0, root.results.length - 1)
  }

  function activate(i) {
    const entry = root.results[i]
    if (!entry)
      return
    root.forceClose()
    root.choose(entry.action)
  }

  readonly property int gridCols: Math.max(1, Math.ceil(Math.sqrt(root.results.length)))
  readonly property int gridRows: Math.ceil(root.results.length / gridCols)
  readonly property int boxWidth: gridCols * root.cellW + 16
  readonly property int boxHeight: searchRow.height + 12 + root.gridRows * root.cellH + 12

  PanelWindow {
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    margins.top: 30
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    visible: root.open || root.closePending

    onVisibleChanged: { if (visible && root.open) search.forceActiveFocus() }

    Timer {
      running: root.open && !root.closePending
      repeat: true
      interval: 500
      onTriggered: { if (root.open) search.forceActiveFocus() }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.requestClose()
    }

    Rectangle {
      id: card
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: parent.right
      anchors.rightMargin: 20
      width: root.boxWidth
      height: root.boxHeight
      color: "#000000"
      border.color: "#ffffff"
      border.width: 1
      opacity: root.open ? 1 : 0
      x: root.open ? parent.width - width - 20 : parent.width + 20
      Behavior on x { NumberAnimation { duration: 200; easing.type: Theme.easingOut } }
      Behavior on opacity { NumberAnimation { duration: 150; easing.type: Theme.easingOut } }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Rectangle {
          id: searchRow
          Layout.fillWidth: true
          Layout.preferredHeight: 28
          color: "transparent"
          border.color: "#ffffff"
          border.width: 1
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 6
            Text {
              text: "󰍉"
              color: "#ffffff"
              font.family: root.fontFamily
              font.pixelSize: 14
              verticalAlignment: Text.AlignVCenter
              Layout.alignment: Qt.AlignVCenter
            }
            Item {
              Layout.fillWidth: true
              Layout.fillHeight: true
              Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: "Search"
                color: "#666666"
                font.family: root.fontFamily
                font.pixelSize: 12
                visible: search.text === ""
                elide: Text.ElideRight
              }
              TextInput {
                id: search
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                font.family: root.fontFamily
                font.pixelSize: 12
                color: "#ffffff"
                clip: true
                focus: true
                onTextChanged: root.query = text
                onVisibleChanged: {
                  if (visible) {
                    text = ""
                    forceActiveFocus()
                  }
                }
                Keys.onEscapePressed: root.requestClose()
                Keys.onUpPressed: root.selIdx = Math.max(0, root.selIdx - root.gridCols)
                Keys.onDownPressed: root.selIdx = Math.min(root.results.length - 1, root.selIdx + root.gridCols)
                Keys.onLeftPressed: root.selIdx = Math.max(0, root.selIdx - 1)
                Keys.onRightPressed: root.selIdx = Math.min(root.results.length - 1, root.selIdx + 1)
                Keys.onReturnPressed: root.activate(root.selIdx)
                Keys.onEnterPressed: root.activate(root.selIdx)
                Keys.onPressed: event => {
                  if ((event.key === Qt.Key_N || event.key === Qt.Key_P) && (event.modifiers & Qt.ControlModifier)) {
                    root.selIdx = event.key === Qt.Key_N ? Math.min(root.results.length - 1, root.selIdx + 1) : Math.max(0, root.selIdx - 1)
                    event.accepted = true
                  }
                }
              }
            }
          }
        }

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          Flow {
            id: grid
            anchors.fill: parent
            spacing: 0

            Repeater {
              model: root.results
              delegate: Rectangle {
                required property var modelData
                required property int index
                width: root.cellW
                height: root.cellH
                color: root.selIdx === index ? "#ffffff" : root.hoverIdx === index ? "#33ffffff" : "transparent"

                RowLayout {
                  anchors.centerIn: parent
                  spacing: 10

                  Text {
                    text: modelData.glyph
                    color: root.selIdx === index ? "#000000" : "#ffffff"
                    font.family: root.fontFamily
                    font.pixelSize: 24
                  }

                  Text {
                    text: modelData.name
                    color: root.selIdx === index ? "#000000" : "#ffffff"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    clip: true
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: { root.hoverIdx = index }
                  onExited: { if (root.hoverIdx === index) root.hoverIdx = -1 }
                  onClicked: root.activate(index)
                }
              }
            }
          }
        }
      }
    }
  }
}
