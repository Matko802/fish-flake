import QtQuick
import Quickshell
import Quickshell.Io

Row {
  spacing: 4

  Repeater {
    id: repeater
    model: []
    property string lastJson: ""
    delegate: Rectangle {
      property bool hovered: workspaceMa.containsMouse
      width: 20
      height: 20
      color: modelData.urgent ? "#ff0000" : (modelData.active ? "#ffffff" : (hovered ? "#333333" : "transparent"))
      border.color: hovered ? "#ffffff" : "transparent"
      border.width: 1

      Text {
        anchors.centerIn: parent
        text: modelData.index
        color: modelData.urgent || modelData.active ? "#000000" : (hovered ? "#ffffff" : "#888888")
        font.pixelSize: 11
      }

      MouseArea {
        id: workspaceMa
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
          // Niri if available, else mango mmsg
          if (niriCheck.isNiri) {
            if (mouse.button === Qt.RightButton)
              Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(modelData.index)])
            else
              Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(modelData.index)])
          } else {
            if (mouse.button === Qt.RightButton)
              Quickshell.execDetached(["mmsg", "dispatch", "toggle," + modelData.index])
            else
              Quickshell.execDetached(["mmsg", "dispatch", "view," + modelData.index + ",0"])
          }
        }
      }
    }
  }

  // Detect compositor once
  Process {
    id: niriCheck
    property bool isNiri: false
    running: true
    command: ["sh", "-c", "command -v niri >/dev/null 2>&1 && niri msg -j workspaces >/dev/null 2>&1 && echo niri || echo mango"]
    stdout: SplitParser {
      onRead: data => {
        niriCheck.isNiri = data.trim() === "niri"
        if (niriCheck.isNiri) {
          niriInit.running = true
        } else {
          mangoWatch.running = true
        }
      }
    }
  }

  // Niri: initial fetch
  Process {
    id: niriInit
    running: false
    command: ["niri", "msg", "-j", "workspaces"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const arr = JSON.parse(data)
          updateFromNiri(arr)
        } catch (e) {}
      }
    }
  }

  // Niri: event-stream instant + poll fallback
  Process {
    id: niriWatch
    running: true
    command: ["sh", "-c", "command -v niri >/dev/null 2>&1 && stdbuf -oL niri msg -j event-stream 2>/dev/null || sleep 999999"]
    stdout: SplitParser {
      onRead: data => {
        // Fast path for workspace changes
        try {
          const j = JSON.parse(data)
          const ws = j.WorkspacesChanged?.workspaces
          if (ws) { updateFromNiri(ws); return }
        } catch (e) {}
        // Window open/close changes occupancy -> poll workspaces
        if (data.includes("Window") && !niriPoll.running) niriPoll.running = true
      }
    }
  }
  // Fallback poll: faster for responsiveness (150ms)
  Timer {
    interval: 150
    running: niriCheck.isNiri
    repeat: true
    triggeredOnStart: true
    onTriggered: { if (!niriPoll.running) niriPoll.running = true }
  }
  Process {
    id: niriPoll
    running: false
    command: ["niri", "msg", "-j", "workspaces"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const arr = JSON.parse(data)
          updateFromNiri(arr)
        } catch (e) {}
      }
    }
  }

  function updateFromNiri(arr) {
    const next = arr.filter(w => w.is_focused || w.active_window_id !== null || w.is_urgent).map(w => ({
      index: w.idx,
      active: !!w.is_focused,
      occupied: w.active_window_id !== null,
      urgent: !!w.is_urgent
    })).sort((a, b) => a.index - b.index)
    const json = JSON.stringify(next)
    if (json !== repeater.lastJson) {
      repeater.lastJson = json
      repeater.model = next
    }
  }

  // Mango fallback: all-tags
  Process {
    id: mangoWatch
    running: false
    command: ["stdbuf", "-oL", "mmsg", "watch", "all-tags"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const d = JSON.parse(data)
          const groups = d.all_tags || []
          const arr = groups.length ? (groups[0].tags || []) : []
          const next = arr
            .filter(t => t.is_active || (t.client_count || 0) > 0 || !!t.is_urgent)
            .map(t => ({
              index: t.index,
              active: !!t.is_active,
              occupied: (t.client_count || 0) > 0,
              urgent: !!t.is_urgent
            }))
          const json = JSON.stringify(next)
          if (json !== repeater.lastJson) {
            repeater.lastJson = json
            repeater.model = next
          }
        } catch (e) {}
      }
    }
  }
}
