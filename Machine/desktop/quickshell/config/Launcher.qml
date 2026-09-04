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
  property string filterQuery: ""
  property int selIdx: 0
  property int hoverIdx: -1
  property bool mouseOverList: false
  readonly property string fontFamily: Theme.fontFamily
  readonly property color matchColor: "#cb4b16"

  // Terminal handling — works with any installed terminal.
  // Respects $TERMINAL, then xdg-terminal-exec, then common terminals.
  property var terminalCmd: ["kitty", "-e"]
  property int termProbeIdx: 0
  readonly property var termCandidates: [
    { bin: "xdg-terminal-exec", cmd: ["xdg-terminal-exec"] },
    { bin: "kitty", cmd: ["kitty", "-e"] },
    { bin: "alacritty", cmd: ["alacritty", "-e"] },
    { bin: "foot", cmd: ["foot"] },
    { bin: "wezterm", cmd: ["wezterm", "start", "--"] },
    { bin: "gnome-terminal", cmd: ["gnome-terminal", "--"] },
    { bin: "konsole", cmd: ["konsole", "-e"] },
    { bin: "xfce4-terminal", cmd: ["xfce4-terminal", "-e"] },
    { bin: "tilix", cmd: ["tilix", "-e"] },
    { bin: "xterm", cmd: ["xterm", "-e"] }
  ]
  Component.onCompleted: {
    const envTerm = Quickshell.env("TERMINAL")
    if (envTerm && envTerm.length > 0) {
      const t = envTerm.trim().split(/\s+/)[0]
      if (t === "foot") root.terminalCmd = ["foot"]
      else if (t === "wezterm") root.terminalCmd = ["wezterm", "start", "--"]
      else if (t === "gnome-terminal") root.terminalCmd = ["gnome-terminal", "--"]
      else if (t === "xdg-terminal-exec") root.terminalCmd = ["xdg-terminal-exec"]
      else root.terminalCmd = [t, "-e"]
      return
    }
    termProbe.running = true
  }
  Process {
    id: termProbe
    running: false
    onExited: exitCode => {
      const cand = root.termCandidates[root.termProbeIdx]
      if (exitCode === 0 && cand) {
        root.terminalCmd = cand.cmd
        return
      }
      root.termProbeIdx += 1
      if (root.termProbeIdx < root.termCandidates.length) {
        termProbe.command = ["sh", "-c", "command -v " + root.termCandidates[root.termProbeIdx].bin + " >/dev/null"]
        termProbe.running = true
      }
    }
    Component.onCompleted: {
      if (root.termCandidates.length > 0) {
        termProbe.command = ["sh", "-c", "command -v " + root.termCandidates[0].bin + " >/dev/null"]
      }
    }
  }

  // Debounce the actual filter: typing stays responsive, but the list + resize
  // animation only recompute after a short pause, so fast typing doesn't rebuild
  // the ListView and restart the height animation on every keystroke.
  Timer {
    id: searchTimer
    interval: 60
    onTriggered: root.filterQuery = root.query
  }

  // Runs the raw query as a shell command (used when no app matches).
  Process {
    id: cmdRunner
  }

  // Keep the surface mapped briefly after a key/mouse-initiated close so the
  // triggering key's press+release both land here instead of the refocused app
  // (mango transfers held keys on focus change, e.g. Esc unfullscreening video).
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
    root.filterQuery = ""
    searchTimer.stop()
    root.selIdx = 0
    root.hoverIdx = -1
    root.open = true
  }

  function launch(i) {
    const entry = root.results[i]
    if (!entry)
      return
    root.forceClose()
    if (entry.runInTerminal) {
      if (entry.command && entry.command.length > 0) {
        Quickshell.execDetached(root.terminalCmd.concat(entry.command))
      } else {
        let exec = entry.execString ?? ""
        exec = exec.replace(/%[fFuUickdDnNvm]/g, "").trim()
        if (exec === "") exec = entry.execString
        Quickshell.execDetached(root.terminalCmd.concat(["sh", "-c", exec]))
      }
    } else {
      entry.execute()
    }
  }
  function runCommand() {
    const cmd = root.query.trim()
    if (cmd === "")
      return
    root.forceClose()
    cmdRunner.running = false
    cmdRunner.command = ["setsid", "-f", "sh", "-c", cmd]
    cmdRunner.running = true
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

  // Sorted app list, computed once (not per keystroke).
  readonly property var sortedApps: {
    const all = DesktopEntries.applications.values.filter(e => !e.noDisplay)
    return all.slice().sort((a, b) => a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1)
  }

  // Lowercased names, computed once so typing only does a cheap includes().
  readonly property var lcNames: root.sortedApps.map(e => e.name.toLowerCase())

  readonly property var results: {
    const q = root.filterQuery.toLowerCase()
    if (q === "")
      return root.sortedApps
    const out = []
    for (let i = 0; i < root.sortedApps.length; i++)
      if (root.lcNames[i].includes(q))
        out.push(root.sortedApps[i])
    return out
  }

  onQueryChanged: {
    root.selIdx = 0
    root.hoverIdx = -1
    searchTimer.restart()
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
    id: panel
    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    margins.top: 30
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-launcher"
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

    // Full-screen click catcher: clicking outside the card dismisses the launcher,
    // so the window never needs to be box-sized (which forced the layer surface
    // to resize on every search result change -> janky animation).
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
            Item {
              Layout.preferredWidth: 16
              Layout.preferredHeight: 16
              Layout.alignment: Qt.AlignVCenter
              QIcon {
                anchors.centerIn: parent
                name: "search"
                size: 16
                color: "#ffffff"
              }
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
                Keys.onReturnPressed: {
                  if (root.query.trim() !== "" && root.results.length === 0)
                    root.runCommand()
                  else
                    root.launch(root.selIdx)
                }
                Keys.onEnterPressed: {
                  if (root.query.trim() !== "" && root.results.length === 0)
                    root.runCommand()
                  else
                    root.launch(root.selIdx)
                }
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
          Behavior on Layout.preferredHeight { enabled: root.query !== "" && root.open && !root.closePending; NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
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

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: root.query.trim() !== "" && root.results.length === 0 ? 28 : 0
          visible: height > 0
          color: "transparent"
          border.color: "#ffffff"
          border.width: 1
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 8
            Text {
              text: "Run command"
              color: root.matchColor
              font.family: root.fontFamily
              font.pointSize: 12
              Layout.alignment: Qt.AlignVCenter
            }
            Text {
              Layout.fillWidth: true
              text: root.fit(root.query)
              color: "#ffffff"
              font.family: root.fontFamily
              font.pointSize: 12
              elide: Text.ElideRight
            }
          }
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.runCommand()
          }
        }
      }
    }
  }
}
