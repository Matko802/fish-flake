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
  property bool mouseOverList: false
  property string tab: "text"
  property int swipeIdx: 0
  property var allEntries: []
  property var thumbs: ({})
  readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/quickshell/clipboard"
  readonly property string fontFamily: Theme.fontFamily
  readonly property color matchColor: "#cb4b16"

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
    listProc.running = true
  }

  function preview(line) {
    const i = line.indexOf("\t")
    return i >= 0 ? line.slice(i + 1) : line
  }

  function esc(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
  }

  function hl(raw) {
    const p = root.preview(raw)
    const q = root.query.toLowerCase()
    if (q === "")
      return root.esc(p)
    const i = p.toLowerCase().indexOf(q)
    if (i < 0)
      return root.esc(p)
    return root.esc(p.slice(0, i)) + "<font color=\"" + root.matchColor + "\">" + root.esc(p.slice(i, i + q.length)) + "</font>" + root.esc(p.slice(i + q.length))
  }

  function shellEscape(s) {
    return "'" + s.replace(/'/g, "'\\''") + "'"
  }

  function idOf(line) {
    return line.slice(0, line.indexOf("\t"))
  }

  function isImage(line) {
    const p = root.preview(line)
    return p.startsWith("[[ binary data") && / (?:png|jpe?g|gif|bmp|webp)\b/i.test(p)
  }

  function paste(i) {
    const entry = root.results[i]
    if (!entry)
      return
    root.forceClose()
    pasteDelay.restart()
    pasteProc.command = ["sh", "-c", "printf '%s\\n' " + root.shellEscape(entry) + " | cliphist decode | wl-copy"]
  }

  function remove(i) {
    const entry = root.results[i]
    if (!entry)
      return
    delProc.command = ["sh", "-c", "printf '%s\\n' " + root.shellEscape(entry) + " | cliphist delete"]
    delProc.running = true
  }

  Timer {
    id: pasteDelay
    interval: 100
    onTriggered: pasteProc.running = true
  }

  Process {
    id: pasteProc
  }
  Process {
    id: delProc
    onExited: listProc.running = true
  }

  Process {
    id: listProc
    command: ["cliphist", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.allEntries = this.text.split("\n").filter(l => l.trim() !== "" && !root.isEmojiOnly(root.preview(l)))
        thumbProc.running = root.allEntries.some(l => root.isImage(l))
      }
    }
  }

  // Decode image entries once into a thumbnail cache; prints every known id so
  // the picker can tell which thumbnails exist.
  Process {
    id: thumbProc
    command: ["sh", "-c", "mkdir -p \"$HOME/.cache/quickshell/clipboard\"\n"
      + "cliphist list | while IFS= read -r line; do\n"
      + "  prev=${line#*$'\\t'}\n"
      + "  case $prev in \"[[ binary data\"*) ;; *) continue ;; esac\n"
      + "  case $prev in *png*|*jpeg*|*jpg*|*gif*|*bmp*|*webp*) ;; *) continue ;; esac\n"
      + "  id=${line%%$'\\t'*}\n"
      + "  f=\"$HOME/.cache/quickshell/clipboard/$id.png\"\n"
      + "  if [ ! -f \"$f\" ]; then\n"
      + "    printf '%s\\n' \"$line\" | cliphist decode | magick - -resize '256x256>' \"$f\" 2>/dev/null || continue\n"
      + "  fi\n"
      + "  echo \"$id\"\n"
      + "done"]
    stdout: StdioCollector {
      onStreamFinished: {
        const m = {}
        for (const l of this.text.split("\n"))
          if (l.trim() !== "")
            m[l.trim()] = true
        root.thumbs = m
      }
    }
  }

  // Skip entries that consist solely of emoji characters (e.g. from the
  // emoji picker) so they never show up in the history list.
  function isEmojiOnly(s) {
    const t = s.replace(/\s+/g, "")
    if (t === "")
      return false
    const re = /^(?:[\u2600-\u27BF\u2B00-\u2BFF\u{1F000}-\u{1FAFF}\u{1F1E6}-\u{1F1FF}\uFE0F\u200D\u2122\u203C\u2049]|(?:[#*0-9]\uFE0F?\u20E3))+$/
    return re.test(t)
  }

  IpcHandler {
    target: "clipboard"
    function toggle() {
      root.toggle()
    }
    function close() {
      root.forceClose()
    }
  }

  readonly property var results: {
    const q = root.query.toLowerCase()
    return root.allEntries.filter(l => q === "" || root.preview(l).toLowerCase().includes(q))
  }
  readonly property var textEntries: root.results.filter(l => !root.isImage(l))
  readonly property var imageEntries: root.results.filter(l => root.isImage(l))

  onTabChanged: {
    root.selIdx = 0
    root.hoverIdx = -1
    root.swipeIdx = root.tab === "images" ? 1 : 0
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
    const v = root.tab === "images" ? imgGrid : list
    if (v)
      v.positionViewAtIndex(root.selIdx, ListView.Contain)
  }

  TextMetrics {
    id: tm
    font.family: root.fontFamily
    font.pointSize: 12
    text: "M"
  }
  readonly property int boxWidth: Math.round(60 * tm.advanceWidth) + 24
  readonly property int imgCellH: 96

  PanelWindow {
    id: panel
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    margins.top: 30
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-clipboard"
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
      anchors.centerIn: parent
      width: root.boxWidth
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
                Keys.onUpPressed: { root.mouseOverList = false; root.selIdx = Math.max(0, root.selIdx - (root.tab === "images" ? 3 : 1)) }
                Keys.onDownPressed: { root.mouseOverList = false; root.selIdx = Math.min(root.results.length - 1, root.selIdx + (root.tab === "images" ? 3 : 1)) }
                Keys.onLeftPressed: if (root.tab === "images") { root.mouseOverList = false; root.selIdx = Math.max(0, root.selIdx - 1); event.accepted = true }
                Keys.onRightPressed: if (root.tab === "images") { root.mouseOverList = false; root.selIdx = Math.min(root.results.length - 1, root.selIdx + 1); event.accepted = true }
                Keys.onReturnPressed: root.paste(root.selIdx)
                Keys.onEnterPressed: root.paste(root.selIdx)
                Keys.onDeletePressed: root.remove(root.selIdx)
                Keys.onPressed: event => {
                  if ((event.key === Qt.Key_N || event.key === Qt.Key_P) && (event.modifiers & Qt.ControlModifier)) {
                    root.mouseOverList = false; root.selIdx = event.key === Qt.Key_N ? Math.min(root.results.length - 1, root.selIdx + 1) : Math.max(0, root.selIdx - 1)
                    event.accepted = true
                  } else if ((event.key === Qt.Key_D) && (event.modifiers & Qt.ControlModifier)) {
                    root.remove(root.selIdx)
                    event.accepted = true
                  } else if (event.key === Qt.Key_PageDown) {
                    root.mouseOverList = false; root.selIdx = Math.min(root.results.length - 1, root.selIdx + 5 * (root.tab === "images" ? 3 : 1))
                    event.accepted = true
                  } else if (event.key === Qt.Key_PageUp) {
                    root.mouseOverList = false; root.selIdx = Math.max(0, root.selIdx - 5 * (root.tab === "images" ? 3 : 1))
                    event.accepted = true
                  }
                }
              }
            }
          }
        }

        Item {
          id: swipeContainer
          Layout.fillWidth: true
          Layout.preferredHeight: 15 * 28
          clip: true

          Row {
            id: swipeRow
            x: -root.swipeIdx * swipeContainer.width
            Behavior on x { enabled: root.open && !root.closePending; NumberAnimation { duration: 200; easing.type: Theme.easingOut } }
            height: swipeContainer.height

            Item {
              width: swipeContainer.width
              height: swipeContainer.height

              ListView {
                id: list
                anchors.fill: parent
                clip: true
                interactive: true
                flickableDirection: Flickable.VerticalFlick
                spacing: 0
                model: root.textEntries
                highlightMoveDuration: 0

                delegate: Rectangle {
                  required property var modelData
                  required property int index
                  width: list.width
                  height: 28
                  readonly property bool isKeyboardSelected: root.selIdx === index
                  readonly property bool isHovered: root.hoverIdx === index
                  color: isKeyboardSelected ? "#ffffff" : isHovered ? "#33ffffff" : "transparent"

                  Text {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    verticalAlignment: Text.AlignVCenter
                    textFormat: Text.RichText
                    text: root.hl(modelData)
                    color: isKeyboardSelected ? "#586e75" : "#ffffff"
                    font.family: root.fontFamily
                    font.pointSize: 12
                    elide: Text.ElideRight
                    clip: true
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: { root.hoverIdx = index; root.mouseOverList = true }
                    onExited: { if (root.hoverIdx === index) root.hoverIdx = -1; root.mouseOverList = false }
                    onClicked: root.paste(index)
                  }
                }
              }
            }

            Item {
              width: swipeContainer.width
              height: swipeContainer.height

              GridView {
                id: imgGrid
                anchors.fill: parent
                clip: true
                interactive: true
                flickableDirection: Flickable.HorizontalAndVerticalFlick
                cellWidth: Math.floor(imgGrid.width / 3)
                cellHeight: root.imgCellH
                model: root.imageEntries
                highlightMoveDuration: 0

                delegate: Rectangle {
                  required property var modelData
                  required property int index
                  width: imgGrid.cellWidth
                  height: imgGrid.cellHeight
                  readonly property bool isSel: root.selIdx === index
                  readonly property bool isHover: root.hoverIdx === index
                  color: "transparent"

                  Image {
                    anchors.fill: parent
                    anchors.margins: 4
                    source: root.thumbs[root.idOf(modelData)] !== undefined ? "file://" + root.thumbDir + "/" + root.idOf(modelData) + ".png" : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                  }

                  Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    border.width: isSel || isHover ? 1 : 0
                    border.color: "#ffffff"
                    color: "transparent"
                  }

                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: { root.hoverIdx = index; root.selIdx = index; root.mouseOverList = true }
                    onExited: { if (root.hoverIdx === index) root.hoverIdx = -1; root.mouseOverList = false }
                    onClicked: root.paste(index)
                  }
                }
              }
            }
          }
        }

        Text {
          visible: root.results.length === 0
          Layout.fillWidth: true
          Layout.preferredHeight: 22
          verticalAlignment: TextInput.AlignVCenter
          font.family: root.fontFamily
          font.pointSize: 11
          color: "#888888"
          text: root.allEntries.length === 0 ? "clipboard empty" : "no matches"
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 0
          Repeater {
            model: [
              { label: "TEXT", idx: 0 },
              { label: "IMAGES", idx: 1 }
            ]
            delegate: Item {
              required property var modelData
              Layout.fillWidth: true
              Layout.preferredHeight: 28
              property bool active: root.tab === (modelData.idx === 0 ? "text" : "images")
              Text {
                anchors.centerIn: parent
                text: modelData.label
                color: parent.active ? Theme.fg : Theme.muted
                font.family: root.fontFamily
                font.pixelSize: 11
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.tab = modelData.idx === 0 ? "text" : "images"
              }
            }
          }
        }
      }
    }
  }
}
