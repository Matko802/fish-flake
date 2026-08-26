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
  readonly property int rowHeight: 46

  // Keep the surface mapped briefly after a key/mouse-initiated close so the
  // triggering key's press+release both land here instead of the refocused app.
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
    interval: 200
    onTriggered: {
      root.closePending = false
      root.open = false
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
    { name: "Change Wallpaper", glyph: "󰀾", action: "wallpaper" }
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
  onSelIdxChanged: {
    if (list)
      list.positionViewAtIndex(root.selIdx, ListView.Contain)
  }

  function activate(i) {
    const entry = root.results[i]
    if (!entry)
      return
    root.forceClose()
    root.choose(entry.action)
  }

  TextMetrics {
    id: tm
    font.family: root.fontFamily
    font.pointSize: 14
    text: "M"
  }
  readonly property int boxWidth: Math.round(26 * tm.advanceWidth) + 82

  PanelWindow {
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    visible: root.open

    MouseArea {
      anchors.fill: parent
      onClicked: root.requestClose()
    }

    Rectangle {
      id: card
      anchors.centerIn: parent
      width: root.boxWidth
      height: col.implicitHeight + 18
      color: "#000000"
      border.color: "#ffffff"
      border.width: 1

      ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 41
        anchors.rightMargin: 41
        anchors.topMargin: 8
        spacing: 0

        TextInput {
          id: search
          Layout.fillWidth: true
          Layout.preferredHeight: 30
          verticalAlignment: TextInput.AlignVCenter
          font.family: root.fontFamily
          font.pointSize: 13
          color: "#ffffff"
          clip: true
          focus: true
          onTextChanged: root.query = text
          onVisibleChanged: {
            if (visible) {
              forceActiveFocus()
            }
          }
          Keys.onEscapePressed: root.requestClose()
          Keys.onUpPressed: root.selIdx = Math.max(0, root.selIdx - 1)
          Keys.onDownPressed: root.selIdx = Math.min(root.results.length - 1, root.selIdx + 1)
          Keys.onReturnPressed: root.activate(root.selIdx)
          Keys.onEnterPressed: root.activate(root.selIdx)
          Keys.onPressed: event => {
            if ((event.key === Qt.Key_N || event.key === Qt.Key_P) && (event.modifiers & Qt.ControlModifier)) {
              root.selIdx = event.key === Qt.Key_N ? Math.min(root.results.length - 1, root.selIdx + 1) : Math.max(0, root.selIdx - 1)
              event.accepted = true
            } else if (event.key === Qt.Key_PageDown) {
              root.selIdx = Math.min(root.results.length - 1, root.selIdx + 3)
              event.accepted = true
            } else if (event.key === Qt.Key_PageUp) {
              root.selIdx = Math.max(0, root.selIdx - 3)
              event.accepted = true
            }
          }
        }

        ListView {
          id: list
          Layout.fillWidth: true
          Layout.preferredHeight: root.results.length === 0 ? 30 : Math.min(root.results.length * root.rowHeight, 6 * root.rowHeight)
          clip: true
          interactive: true
          spacing: 0
          model: root.results
          highlightMoveDuration: 0

          delegate: Rectangle {
            required property var modelData
            required property int index
            width: list.width
            height: root.rowHeight
            readonly property bool isKeyboardSelected: root.selIdx === index
            readonly property bool isHovered: root.hoverIdx === index
            color: isKeyboardSelected ? "#ffffff" : isHovered ? "#33ffffff" : "transparent"

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 4
              anchors.rightMargin: 4
              spacing: 12

              Text {
                text: modelData.glyph
                color: isKeyboardSelected ? "#000000" : "#ffffff"
                font.family: root.fontFamily
                font.pixelSize: 24
              }

              Text {
                text: modelData.name
                color: isKeyboardSelected ? "#586e75" : "#ffffff"
                font.family: root.fontFamily
                font.pointSize: 14
                elide: Text.ElideRight
                clip: true
                Layout.fillWidth: true
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

        Text {
          visible: root.results.length === 0
          Layout.fillWidth: true
          Layout.preferredHeight: 30
          verticalAlignment: TextInput.AlignVCenter
          text: "no matches"
          color: "#888888"
          font.family: root.fontFamily
          font.pointSize: 13
        }
      }
    }
  }
}
