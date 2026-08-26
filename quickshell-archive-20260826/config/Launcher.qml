import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
  id: root

  property bool open: false
  property string query: ""
  property int selIdx: 0
  property int hoverIdx: -1
  property bool mouseOverList: false
  readonly property string fontFamily: Theme.fontFamily
  readonly property color matchColor: "#cb4b16"

  // Keep the surface mapped briefly after a key/mouse-initiated close so the
  // triggering key's press+release both land here instead of the refocused app
  // (mango transfers held keys on focus change, e.g. Esc unfullscreening video).
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
    if (root.closePending) {
      closeTimer.stop()
      root.closePending = false
      root.open = false
    }
    if (root.open) {
      root.requestClose()
      return
    }
    closeTimer.stop()
    root.closePending = false
    root.query = ""
    root.selIdx = 0
    root.hoverIdx = -1
    root.open = true
  }

  function launch(i) {
    const entry = root.results[i]
    if (!entry)
      return
    root.forceClose()
    entry.execute()
  }
  function esc(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }

  readonly property int maxNameChars: Math.max(8, Math.floor((30 * tm.advanceWidth - 26) / tm.advanceWidth))

  function fit(name) {
    return name.length > root.maxNameChars ? name.slice(0, root.maxNameChars - 1) + "\u2026" : name
  }

  function hl(rawName) {
    const name = root.fit(rawName)
    const q = root.query.toLowerCase()
    if (q === "")
      return esc(name)
    const i = name.toLowerCase().indexOf(q)
    if (i < 0)
      return esc(name)
    return esc(name.slice(0, i)) + "<font color=\"" + root.matchColor + "\">" + esc(name.slice(i, i + q.length)) + "</font>" + esc(name.slice(i + q.length))
  }

  IpcHandler {
    target: "launcher"
    function toggle() {
      root.toggle()
    }
    function close() {
      root.forceClose()
    }
  }

  readonly property var results: {
    const q = root.query.toLowerCase()
    const all = DesktopEntries.applications.values.filter(e => !e.noDisplay)
    const sorted = all.slice().sort((a, b) => a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1)
    if (q === "")
      return sorted
    return sorted.filter(e => e.name.toLowerCase().includes(q))
  }

  onQueryChanged: {
    root.selIdx = 0
    root.hoverIdx = -1
  }
  onResultsChanged: {
    if (root.selIdx >= root.results.length)
      root.selIdx = Math.max(0, root.results.length - 1)
    if (root.hoverIdx >= root.results.length)
      root.hoverIdx = -1
  }
  onSelIdxChanged: {
    if (list)
      list.positionViewAtIndex(root.selIdx, ListView.Contain)
  }

  TextMetrics {
    id: tm
    font.family: root.fontFamily
    font.pointSize: 12
    text: "M"
  }
  readonly property int boxWidth: Math.round(30 * tm.advanceWidth) + 82

  PanelWindow {
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-launcher"
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
      height: col.implicitHeight + 16
      color: "#000000"
      border.color: "#ffffff"
      border.width: 1

      ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 8

        Rectangle {
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
                anchors.leftMargin: 0
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
                Keys.onEscapePressed: event => { root.requestClose(); event.accepted = true }
                Keys.onUpPressed: { root.mouseOverList = false; root.selIdx = Math.max(0, root.selIdx - 1) }
                Keys.onDownPressed: { root.mouseOverList = false; root.selIdx = Math.min(root.results.length - 1, root.selIdx + 1) }
                Keys.onReturnPressed: root.launch(root.selIdx)
                Keys.onEnterPressed: root.launch(root.selIdx)
                Keys.onPressed: event => {
                  if ((event.key === Qt.Key_N || event.key === Qt.Key_P) && (event.modifiers & Qt.ControlModifier)) {
                    root.mouseOverList = false; root.selIdx = event.key === Qt.Key_N ? Math.min(root.results.length - 1, root.selIdx + 1) : Math.max(0, root.selIdx - 1)
                    event.accepted = true
                  } else if (event.key === Qt.Key_PageDown) {
                    root.mouseOverList = false; root.selIdx = Math.min(root.results.length - 1, root.selIdx + 5)
                    event.accepted = true
                  } else if (event.key === Qt.Key_PageUp) {
                    root.mouseOverList = false; root.selIdx = Math.max(0, root.selIdx - 5)
                    event.accepted = true
                  }
                }
              }
            }
          }
        }

        ListView {
          id: list
          Layout.fillWidth: true
          Layout.preferredHeight: root.results.length === 0 ? 0 : Math.min(root.results.length * 28, 15 * 28)
          visible: root.results.length > 0
          Behavior on Layout.preferredHeight { enabled: root.open && !root.closePending; NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
          clip: true
          interactive: true
          spacing: 0
          model: root.results
          highlightMoveDuration: 0

          delegate: Rectangle {
            required property var modelData
            required property int index
            width: list.width
            height: 28
            readonly property bool isKeyboardSelected: root.selIdx === index
            readonly property bool isHovered: root.hoverIdx === index
            color: isKeyboardSelected ? "#ffffff" : isHovered ? "#33ffffff" : "transparent"

            RowLayout {
              anchors.fill: parent
              spacing: 10
              IconImage {
                source: Quickshell.iconPath(modelData.icon !== "" ? modelData.icon : "application-x-executable", "application-x-executable")
                implicitSize: 16
                Layout.alignment: Qt.AlignVCenter
              }
              Text {
                textFormat: Text.RichText
                text: root.hl(modelData.name)
                color: isKeyboardSelected ? "#586e75" : "#ffffff"
                font.family: root.fontFamily
                font.pointSize: 12
                clip: true
                Layout.fillWidth: true
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: { root.hoverIdx = index; root.mouseOverList = true }
              onExited: { if (root.hoverIdx === index) root.hoverIdx = -1; root.mouseOverList = false }
              onClicked: root.launch(index)
            }
          }
        }
      }
    }
  }
}
