import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Normal file selector for the profile picture: browse any folder on disk
// and pick any image. Opened via Settings → Profile picture / Choose
// or `quickshell ipc call avatar toggle`.
Scope {
  id: root

  property bool opened: false
  property bool entered: false
  property int selIdx: 0
  property string currentDir: Quickshell.env("HOME") || "/home/matko"
  property var entryArray: []
  property string filterText: ""

  readonly property string fontFamily: Theme.fontFamily
  readonly property int rowH: 34
  readonly property int rowSpacing: 4
  readonly property int visibleCount: 10

  property bool closePending: false

  function requestClose() {
    if (!root.opened || root.closePending)
      return
    root.closePending = true
    root.entered = false
    closeTimer.restart()
  }

  function forceClose() {
    root.entered = false
    closeTimer.stop()
    root.closePending = false
    root.opened = false
  }

  Timer {
    id: closeTimer
    interval: 250
    onTriggered: {
      root.opened = false
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
    if (root.opened) {
      root.requestClose()
      return
    }
    root.openPicker()
  }

  function open() {
    if (!root.opened)
      root.openPicker()
  }

  function forceOpen() {
    root.openPicker()
  }

  function openPicker() {
    closeTimer.stop()
    root.closePending = false
    root.filterText = ""
    root.selIdx = 0
    root.entryArray = []
    root.entered = false
    listProc.output = ""
    listProc.running = true
  }

  function clearAvatar() {
    AvatarState.clear()
  }

  IpcHandler {
    target: "avatar"
    function toggle() {
      root.toggle()
    }
    function open() {
      root.open()
    }
    function close() {
      root.forceClose()
    }
    function clear() {
      root.clearAvatar()
    }
  }

  function shellQuote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  function fileUrl(path) {
    return "file://" + path.split("/").map(encodeURIComponent).join("/")
  }

  function isImage(name) {
    return /\.(png|jpe?g|webp|gif|bmp|svg)$/i.test(name)
  }

  function itemMatches(entry) {
    if (!filterText)
      return true
    return entry.name.toLowerCase().indexOf(filterText.toLowerCase()) !== -1
  }

  readonly property var results: {
    const out = []
    for (let i = 0; i < entryArray.length; i++)
      if (itemMatches(entryArray[i]))
        out.push(entryArray[i])
    return out
  }

  onFilterTextChanged: { root.selIdx = 0 }
  onResultsChanged: {
    if (root.selIdx >= root.results.length)
      root.selIdx = Math.max(0, root.results.length - 1)
  }
  onSelIdxChanged: {
    if (listView && root.results.length > 0)
      listView.positionViewAtIndex(Math.max(0, root.selIdx - 2), ListView.Beginning)
  }

  function move(step) {
    root.selIdx = Math.max(0, Math.min(root.results.length - 1, root.selIdx + step))
  }

  function goUp() {
    const parts = root.currentDir.split("/").filter(p => p !== "")
    parts.pop()
    root.currentDir = "/" + parts.join("/")
    if (root.currentDir === "/")
      root.currentDir = "/"
    root.refresh()
  }

  function goHome() {
    root.currentDir = Quickshell.env("HOME") || "/home/matko"
    root.refresh()
  }

  function refresh() {
    root.filterText = ""
    root.selIdx = 0
    root.entryArray = []
    listProc.output = ""
    listProc.running = true
  }

  function activate(i) {
    const entry = root.results[i]
    if (!entry)
      return
    if (entry.isDir) {
      root.currentDir = entry.fullPath
      root.refresh()
    } else {
      AvatarState.set(entry.fullPath)
      root.requestClose()
    }
  }

  Process {
    id: listProc
    property string output: ""
    command: ["bash", "-c",
      "dir=" + shellQuote(root.currentDir) + ";"
      + " [[ -d \"$dir\" ]] || exit 0;"
      + " find -L \"$dir\" -maxdepth 1 -mindepth 1 -printf '%y\\t%f\\n' 2>/dev/null | sort"]
    stdout: SplitParser {
      onRead: function(data) {
        listProc.output += data + "\n"
      }
    }
    onExited: root.loadRows(output)
  }

  function loadRows(rows) {
    const entries = []
    for (const row of rows.split("\n")) {
      if (!row)
        continue
      const tab = row.indexOf("\t")
      if (tab < 0)
        continue
      const kind = row.slice(0, tab)
      const name = row.slice(tab + 1)
      if (name === "" || name.startsWith("."))
        continue
      const full = root.currentDir + (root.currentDir.endsWith("/") ? "" : "/") + name
      if (kind.startsWith("d"))
        entries.push({ name: name, fullPath: full, isDir: true })
      else if (root.isImage(name))
        entries.push({ name: name, fullPath: full, isDir: false })
    }
    entries.sort((a, b) => {
      if (a.isDir !== b.isDir)
        return a.isDir ? -1 : 1
      return a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1
    })
    root.entryArray = entries
    if (!root.opened) {
      root.opened = true
      root.entered = true
    }
    listView.forceActiveFocus()
  }

  PanelWindow {
    visible: root.opened || root.closePending
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    margins.top: 30
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-avatar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    MouseArea {
      anchors.fill: parent
      onClicked: root.requestClose()
    }

    Rectangle {
      id: panel
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.topMargin: 50
      anchors.leftMargin: root.opened ? 20 : -width
      width: 400
      height: listViewCol.implicitHeight + 16
      color: "#000000"
      border.color: "#ffffff"
      border.width: 1
      Behavior on anchors.leftMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

      Column {
        id: listViewCol
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        Text {
          width: parent.width
          text: "Profile picture — pick an image"
          color: "#ffffff"
          font.family: root.fontFamily
          font.pixelSize: 11
        }

        RowLayout {
          width: parent.width
          spacing: 6
          Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 26
            radius: 3
            color: upMa.containsMouse ? "#ffffff" : "transparent"
            border.color: "#ffffff"
            border.width: 1
            QIcon { anchors.centerIn: parent; name: "arrow-up"; size: 16; color: upMa.containsMouse ? "#000000" : "#ffffff" }
            MouseArea { id: upMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.goUp() }
          }
          Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 26
            radius: 3
            color: homeMa.containsMouse ? "#ffffff" : "transparent"
            border.color: "#ffffff"
            border.width: 1
            QIcon { anchors.centerIn: parent; name: "home"; size: 16; color: homeMa.containsMouse ? "#000000" : "#ffffff" }
            MouseArea { id: homeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.goHome() }
          }
          Text {
            Layout.fillWidth: true
            text: root.currentDir
            color: "#ffffff"
            opacity: 0.7
            font.family: root.fontFamily
            font.pixelSize: 10
            elide: Text.ElideMiddle
          }
          Rectangle {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 26
            radius: 3
            color: clearMa.containsMouse ? "#ffffff" : "transparent"
            border.color: "#ffffff"
            border.width: 1
            Text {
              anchors.centerIn: parent
              text: "Clear"
              color: clearMa.containsMouse ? "#000000" : "#ffffff"
              font.family: root.fontFamily
              font.pixelSize: 11
            }
            MouseArea {
              id: clearMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.clearAvatar()
            }
          }
        }

        ListView {
          id: listView
          width: parent.width
          height: Math.min(root.visibleCount, Math.max(1, root.results.length)) * (root.rowH + root.rowSpacing)
          clip: true
          spacing: root.rowSpacing
          model: root.results
          highlightMoveDuration: 150
          highlightMoveVelocity: -1

          focus: true

          Keys.priority: Keys.BeforeItem
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
              if (root.filterText) {
                root.filterText = ""
              } else {
                root.requestClose()
              }
              event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.activate(root.selIdx)
              event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
              if (root.filterText.length > 0)
                root.filterText = root.filterText.slice(0, -1)
              else
                root.goUp()
              event.accepted = true
            } else if (event.key === Qt.Key_Up) {
              root.move(-1)
              event.accepted = true
            } else if (event.key === Qt.Key_Down) {
              root.move(1)
              event.accepted = true
            } else if (event.key === Qt.Key_PageUp) {
              root.move(-root.visibleCount)
              event.accepted = true
            } else if (event.key === Qt.Key_PageDown) {
              root.move(root.visibleCount)
              event.accepted = true
            } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && event.text.charCodeAt(0) !== 127 && (event.modifiers === Qt.NoModifier || event.modifiers === Qt.ShiftModifier)) {
              root.filterText += event.text
              event.accepted = true
            }
          }

          delegate: Rectangle {
            required property var modelData
            required property int index
            width: listView.width
            height: root.rowH
            color: root.selIdx === index ? "#ffffff" : (rowMa.containsMouse ? "#33ffffff" : "transparent")

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              spacing: 10
              Item {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                QIcon {
                  anchors.centerIn: parent
                  visible: modelData.isDir
                  name: "folder"
                  size: 20
                  color: root.selIdx === index ? "#000000" : "#ffffff"
                }
                Rectangle {
                  anchors.centerIn: parent
                  visible: !modelData.isDir
                  width: 26
                  height: 26
                  clip: true
                  color: "#111111"
                  Image {
                    anchors.fill: parent
                    source: !modelData.isDir ? root.fileUrl(modelData.fullPath) : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                  }
                }
              }
              Text {
                Layout.fillWidth: true
                text: modelData.name
                color: root.selIdx === index ? "#000000" : "#ffffff"
                font.family: root.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
              }
            }

            MouseArea {
              id: rowMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: { root.selIdx = index; root.activate(index) }
            }
          }

          Text {
            visible: root.results.length === 0
            anchors.centerIn: parent
            text: "no images here"
            color: "#888888"
            font.family: root.fontFamily
            font.pointSize: 11
          }
        }

        Text {
          visible: root.filterText !== ""
          width: parent.width
          text: "filter: " + root.filterText
          color: "#ffffff"
          opacity: 0.6
          font.family: root.fontFamily
          font.pixelSize: 10
          elide: Text.ElideRight
        }
      }
    }
  }
}
