import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
  id: root

  property bool open: false
  property string query: ""
  property int selIdx: 0
  property int hoverIdx: -1
  readonly property string fontFamily: Theme.fontFamily
  readonly property int cols: 10
  readonly property int cellSize: 44
  readonly property int visibleRows: 5

  // Keep the surface mapped briefly after a key/mouse-initiated close so the
  // triggering key's press+release both land here instead of the refocused app.
  property bool closePending: false

  function requestClose() {
    if (!root.open || root.closePending)
      return
    root.closePending = true
    root.open = false
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

  function pick(i) {
    const entry = root.allEmojis[root.results[i]]
    if (!entry)
      return
    root.forceClose()
    pasteDelay.restart()
    pasteProc.command = ["sh", "-c", "printf %s '" + entry.replace(/'/g, "'\\''") + "' | wl-copy && sleep 0.15 && wtype -M ctrl v -m ctrl"]
  }

  Timer {
    id: pasteDelay
    interval: 100
    onTriggered: pasteProc.running = true
  }

  Process {
    id: pasteProc
  }

  IpcHandler {
    target: "emoji"
    function toggle() {
      root.toggle()
    }
    function close() {
      root.forceClose()
    }
  }

  // bemoji-style database, one entry per line:
  // "<emoji> <main name>\t<search keywords>"
  readonly property string dataPath: {
    const u = Qt.resolvedUrl("emojis.txt").toString()
    return u.startsWith("file://") ? decodeURIComponent(u.slice(7)) : u
  }
  property var rows: []

  FileView {
    path: root.dataPath
    watchChanges: true
    onLoaded: root.rows = text().split("\n").filter(l => l !== "")
    onFileChanged: reload()
  }

  readonly property var allEmojis: rows.map(r => r.slice(0, r.indexOf(" ")))

  function nameOf(i) {
    const r = root.rows[i]
    return r ? r.slice(r.indexOf(" ") + 1, r.indexOf("\t")) : ""
  }

  function searchText(i) {
    const r = root.rows[i]
    if (!r)
      return ""
    return r.slice(r.indexOf(" ") + 1).replace("\t", " ")
  }

  function searchMatch(name, q) {
    if (name.indexOf(q) >= 0)
      return true
    let initials = ""
    for (const w of name.split(" "))
      if (w.length > 0)
        initials += w[0]
    if (initials.indexOf(q) >= 0)
      return true
    let j = 0
    for (let k = 0; k < name.length && j < q.length; k++)
      if (name[k] === q[j])
        j++
    return j === q.length
  }

  // Lowercased search strings, computed once when rows loads (not per keystroke).
  readonly property var lcSearch: root.rows.map((_, i) => root.searchText(i).toLowerCase())

  // Resolved indices into allEmojis/rows.
  readonly property var results: {
    const q = query.toLowerCase().trim()
    const idxs = []
    for (let i = 0; i < rows.length; i++)
      if (q === "" || searchMatch(root.lcSearch[i], q))
        idxs.push(i)
    return idxs
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
    if (grid)
      grid.positionViewAtIndex(root.selIdx, GridView.Contain)
  }

  PanelWindow {
    id: panel
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    margins.top: 30
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-emoji"
    WlrLayershell.layer: WlrLayer.Top
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
      anchors.centerIn: parent
      width: root.cols * root.cellSize + 20
      height: col.implicitHeight + 16
      color: "#000000"
      border.color: "#ffffff"
      border.width: 1
      scale: root.open ? 1 : 0.92
      opacity: root.open ? 1 : 0
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Theme.easingOut } }
      Behavior on opacity { NumberAnimation { duration: 150; easing.type: Theme.easingOut } }

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
                Keys.onReturnPressed: root.pick(root.selIdx)
                Keys.onEnterPressed: root.pick(root.selIdx)
                Keys.onDownPressed: event => {
                  grid.forceActiveFocus()
                  root.hoverIdx = -1
                  root.selIdx = Math.min(root.results.length - 1, root.cols - 1)
                  event.accepted = true
                }
              }
            }
          }
        }

        GridView {
          id: grid
          Layout.fillWidth: true
          Layout.preferredHeight: Math.min(Math.ceil(root.results.length / root.cols), root.visibleRows) * root.cellSize
          Behavior on Layout.preferredHeight { enabled: root.open && !root.closePending; NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
          clip: true
          interactive: true
          cellWidth: root.cellSize
          cellHeight: root.cellSize
          model: root.results

          Keys.onEscapePressed: event => { root.requestClose(); event.accepted = true }
          Keys.onReturnPressed: root.pick(root.selIdx)
          Keys.onEnterPressed: root.pick(root.selIdx)
          Keys.onPressed: event => {
            if (event.key === Qt.Key_Up && root.selIdx < root.cols) {
              search.forceActiveFocus()
              root.hoverIdx = -1
              event.accepted = true
              return
            }
            const step = event.key === Qt.Key_Left ? -1
                : event.key === Qt.Key_Right ? 1
                : event.key === Qt.Key_Up ? -root.cols
                : event.key === Qt.Key_Down ? root.cols
                : event.key === Qt.Key_PageUp ? -root.cols * root.visibleRows
                : event.key === Qt.Key_PageDown ? root.cols * root.visibleRows
                : 0
            if (step !== 0) {
              root.hoverIdx = -1
              root.selIdx = Math.max(0, Math.min(root.results.length - 1, root.selIdx + step))
              event.accepted = true
            }
          }

          delegate: Rectangle {
            required property var modelData
            required property int index
            width: grid.cellWidth
            height: grid.cellHeight
            readonly property bool isKeyboardSelected: root.selIdx === index
            readonly property bool isHovered: root.hoverIdx === index
            color: isKeyboardSelected ? "#ffffff" : isHovered ? "#33ffffff" : "transparent"

            Text {
              anchors.centerIn: parent
              text: root.allEmojis[parent.modelData]
              font.pixelSize: 22
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: { root.hoverIdx = index; root.selIdx = index }
              onExited: { if (root.hoverIdx === index) root.hoverIdx = -1 }
              onClicked: root.pick(index)
            }
          }
        }

        Text {
          Layout.fillWidth: true
          Layout.preferredHeight: 18
          elide: Text.ElideRight
          font.family: root.fontFamily
          font.pointSize: 10
          color: "#ffffff"
          text: {
            const i = root.results[root.selIdx]
            return i !== undefined && root.rows.length > 0 ? root.nameOf(i) : "no matches"
          }
        }
      }
    }
  }
}
