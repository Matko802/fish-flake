import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
  id: root

  property bool shown: false
  property bool closePending: false
  property bool loading: false
  property var monitors: []
  property var clients: []
  property var items: []
  property int selIdx: 0
  property var monThumbs: ({})

  readonly property string fontFamily: Theme.fontFamily
  readonly property color border: "#ffffff"
  readonly property int monThumbW: 160
  readonly property int monThumbH: 90

  readonly property string rt: Quickshell.env("XDG_RUNTIME_DIR") !== "" ? Quickshell.env("XDG_RUNTIME_DIR") : ("/run/user/" + (Quickshell.env("UID") !== "" ? Quickshell.env("UID") : "1000"))
  readonly property string ssDir: rt + "/quickshell/screencast"
  readonly property string reqPath: ssDir + "/request"
  readonly property string selPath: ssDir + "/selection"

  readonly property string capScriptPath: (() => { const u = Qt.resolvedUrl("screencast-cap.sh").toString(); return u.startsWith("file://") ? decodeURIComponent(u.slice(7)) : u })()

  function rebuild() {
    const out = []
    for (const m of root.monitors)
      out.push({ kind: "Monitor", label: "Screen " + m.name, sub: m.width + "x" + m.height, value: "Monitor: " + m.name, monName: m.name, appid: "", onScreen: true })
    for (const c of root.clients) {
      const title = (c.title && c.title.trim() !== "") ? c.title : (c.appid || "Window")
      out.push({ kind: "Window", label: title, sub: c.appid || "", value: "Window: " + c.foreign_toplevel_id, appid: c.appid || "" })
    }
    root.items = out
    root.selIdx = 0
  }

  function open() {
    if (root.shown || root.loading || root.closePending)
      return
    root.closePending = false
    root.loading = true
    root.monitors = []
    root.clients = []
    root.items = []
    root.monThumbs = {}
    snapProc.running = true
  }

  function cancel() {
    rmReq.running = true
    root.shown = false
    root.loading = false
    root.closePending = true
  }

  function choose(value) {
    if (!value)
      return
    writeSel.command = ["sh", "-c", "printf '%s\\n' \"$1\" > \"$2\"", "_", value, root.selPath]
    writeSel.running = true
    rmReq.running = true
    root.shown = false
    root.loading = false
    root.closePending = true
  }

  Timer {
    id: closeTimer
    interval: 200
    onTriggered: root.closePending = false
  }

  Timer {
    interval: 250
    running: true
    repeat: true
    onTriggered: reqCheck.running = true
  }

  Process {
    id: reqCheck
    running: false
    command: ["test", "-f", root.reqPath]
    onExited: (exitCode) => { if (exitCode === 0 && !root.shown && !root.closePending) root.open() }
  }

  Process {
    id: snapProc
    running: false
    command: ["sh", root.capScriptPath, root.ssDir]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const obj = JSON.parse(this.text)
          root.monitors = obj.monitors || []
          root.clients = obj.windows || []
        } catch (e) { root.monitors = []; root.clients = [] }
         const map = {}
        for (const m of root.monitors)
          map[m.name] = root.ssDir + "/ss-" + m.name + ".png"
        root.monThumbs = map
        root.rebuild()
        root.loading = false
        root.shown = true
      }
    }
  }

  Process { id: writeSel; running: false }
  Process {
    id: rmReq
    running: false
    command: ["rm", "-f", root.reqPath]
    onExited: closeTimer.restart()
  }

  PanelWindow {
    id: panel
    visible: root.shown || root.closePending
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-screencast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onVisibleChanged: { if (visible) keyboardCatcher.forceActiveFocus() }

    MouseArea {
      anchors.fill: parent
      onClicked: root.cancel()
    }

    Rectangle {
      id: card
      anchors.centerIn: parent
      width: 540
      height: Math.min(col.implicitHeight + 16, 720)
      color: "#000000"
      border.color: root.border
      border.width: 1
      scale: root.shown ? 1 : 0.92
      opacity: root.shown ? 1 : 0
      Behavior on scale { NumberAnimation { duration: 180; easing.type: Theme.easingOut } }
      Behavior on opacity { NumberAnimation { duration: 150; easing.type: Theme.easingOut } }

      ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 8

        Flickable {
          Layout.fillWidth: true
          Layout.preferredHeight: Math.min(listCol.implicitHeight, 600)
          contentHeight: listCol.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          Column {
            id: listCol
            width: parent.width
            spacing: 4

            Repeater {
              model: root.items
              Rectangle {
                required property var modelData
                required property int index
                width: listCol.width
                height: modelData.kind === "Monitor" ? 100 : 76
                readonly property bool isSel: root.selIdx === index
                color: isSel ? "#ffffff" : "transparent"
                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 8
                  anchors.rightMargin: 8
                  spacing: 10
                  Item {
                    visible: modelData.kind === "Monitor"
                    Layout.preferredWidth: root.monThumbW
                    Layout.preferredHeight: root.monThumbH
                    Rectangle {
                      anchors.fill: parent
                      color: "#111111"
                      border.color: root.border
                      border.width: 1
                      clip: true
                      Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        source: root.monThumbs[modelData.monName] ? "file://" + root.monThumbs[modelData.monName] : ""
                      }
                    }
                  }
                  IconImage {
                    visible: modelData.kind === "Window"
                    source: Quickshell.iconPath(modelData.appid !== "" ? modelData.appid : "application-x-executable", "application-x-executable")
                    implicitSize: 28
                  }
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                      text: modelData.label
                      color: isSel ? "#000000" : root.border
                      font.family: root.fontFamily
                      font.pixelSize: 12
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: root.selIdx = index
                  onClicked: root.choose(modelData.value)
                }
              }
            }
          }
        }
      }

      Item {
        id: keyboardCatcher
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: { root.cancel(); event.accepted = true }
        Keys.onUpPressed: { root.selIdx = Math.max(0, root.selIdx - 1); event.accepted = true }
        Keys.onDownPressed: { root.selIdx = Math.min(root.items.length - 1, root.selIdx + 1); event.accepted = true }
        Keys.onReturnPressed: { if (root.items[root.selIdx]) root.choose(root.items[root.selIdx].value); event.accepted = true }
        Keys.onEnterPressed: { if (root.items[root.selIdx]) root.choose(root.items[root.selIdx].value); event.accepted = true }
      }
    }
  }
}
