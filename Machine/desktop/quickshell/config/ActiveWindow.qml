import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

RowLayout {
  id: root
  spacing: Theme.spacingS

  property string appId: ""
  property string appTitle: ""

  IconImage {
    id: appIcon
    Layout.preferredWidth: 16
    Layout.preferredHeight: 16
    Layout.alignment: Qt.AlignVCenter
    visible: root.appId !== ""
    implicitSize: 16
    source: {
      if (root.appId === "") return ""
      const de = DesktopEntries.heuristicLookup(root.appId)
      if (de && de.icon) return Quickshell.iconPath(de.icon, "application-x-executable")
      return Quickshell.iconPath(root.appId, "application-x-executable")
    }
  }

  Text {
    id: windowLabel
    text: root.appTitle
    color: "#ffffff"
    font.pixelSize: 12
    font.family: Theme.fontFamily
    elide: Text.ElideRight
    Layout.maximumWidth: 300
  }

  Process {
    id: niriCheck
    property bool isNiri: false
    property bool decided: false
    running: true
    command: ["sh", "-c", "command -v niri >/dev/null 2>&1 && echo niri || echo mango"]
    stdout: SplitParser {
      onRead: data => {
        const v = data.trim()
        niriCheck.isNiri = v === "niri"
        niriCheck.decided = true
        if (niriCheck.isNiri) {
          niriWatch.running = true
        } else {
          mangoWatch.running = true
        }
      }
    }
  }

  function setFromTitleId(title, appid) {
    let t = String(title || "")
    if (t.length > 40) t = t.slice(0, 39) + "…"
    root.appTitle = t
    root.appId = String(appid || "")
  }

  Process {
    id: niriPoll
    running: false
    command: ["niri", "msg", "-j", "focused-window"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const d = JSON.parse(text.trim())
          if (!d || d.title === undefined) {
            setFromTitleId("", "")
            return
          }
          setFromTitleId(d.title, d.app_id)
        } catch (e) {
        }
      }
    }
  }
  Timer {
    id: niriTimer
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (niriCheck.isNiri && !niriPoll.running) niriPoll.running = true
      if (!niriCheck.decided && !niriPoll.running) niriPoll.running = true
    }
  }

  Process {
    id: niriWatch
    running: false
    command: ["sh", "-c", "command -v niri >/dev/null 2>&1 && stdbuf -oL niri msg -j event-stream 2>/dev/null || sleep 999999"]
    stdout: SplitParser {
      onRead: data => {
        if (data.length < 2) return
        if (data.includes("Window") || data.includes("Workspace") || data.includes("Title")) {
          if (!niriPoll.running) niriPoll.running = true
          try {
            const j = JSON.parse(data)
            const wins = j.WindowsChanged?.windows || (j.WindowOpenedOrChanged?.window ? [j.WindowOpenedOrChanged.window] : null)
            if (wins) {
              const arr = Array.isArray(wins) ? wins : [wins]
              const focused = arr.find(w => w.is_focused)
              if (focused) { setFromTitleId(focused.title, focused.app_id); return }
            }
          } catch (e) {}
        }
      }
    }
  }

  Process {
    id: mangoWatch
    running: false
    command: ["stdbuf", "-oL", "mmsg", "watch", "focusing-client"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const d = JSON.parse(data)
          let t = String(d.title || "")
          if (t.length > 40) t = t.slice(0, 39) + "…"
          root.appTitle = t
          root.appId = String(d.appid || d.appId || "")
        } catch (e) {}
      }
    }
  }
}
