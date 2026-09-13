import QtQuick
import Quickshell
import Quickshell.Io

Text {
  id: langLabel
  text: "?"
  color: "#ffffff"
  font.pixelSize: 12

  property var layoutNames: []

  function setLang(idx, allowPoll) {
    const names = langLabel.layoutNames
    const cur = String(names[idx] || "").toLowerCase()
    if (cur.startsWith("slovak")) langLabel.text = "sk"
    else if (cur.startsWith("english")) langLabel.text = "us"
    else if (cur !== "") langLabel.text = cur.split(/[\s(]/)[0] || "?"
    else if (allowPoll && !niriPoll.running) niriPoll.running = true
  }

  Process {
    id: niriInit
    running: true
    command: ["sh", "-c", "command -v niri >/dev/null 2>&1 && niri msg -j keyboard-layouts 2>/dev/null || echo ''"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const d = JSON.parse(data)
          if (d.names) langLabel.layoutNames = d.names
          setLang(d.current_idx ?? 0, false)
        } catch (e) {}
      }
    }
  }

  Process {
    id: niriPoll
    running: false
    command: ["sh", "-c", "niri msg -j keyboard-layouts 2>/dev/null || echo ''"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const d = JSON.parse(data)
          if (d.names) langLabel.layoutNames = d.names
          setLang(d.current_idx ?? 0, false)
        } catch (e) {}
      }
    }
  }

  Process {
    id: niriWatch
    running: true
    command: ["sh", "-c", "command -v niri >/dev/null 2>&1 && stdbuf -oL niri msg -j event-stream 2>/dev/null || sleep 999999"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const j = JSON.parse(data)
          const k = j.KeyboardLayoutsChanged?.keyboard_layouts
          if (k) {
            if (k.names) langLabel.layoutNames = k.names
            setLang(k.current_idx ?? 0, true)
            return
          }
          const s = j.KeyboardLayoutSwitched
          if (s) setLang(s.idx ?? 0, true)
        } catch (e) {}
      }
    }
  }

  Process {
    running: true
    command: ["sh", "-c", "command -v mmsg >/dev/null 2>&1 && stdbuf -oL mmsg watch keyboardlayout 2>/dev/null || sleep 999999"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const d = JSON.parse(data)
          const name = String(d.layout || "").toLowerCase()
          if (name.startsWith("slovak"))
            langLabel.text = "sk"
          else if (name.startsWith("english"))
            langLabel.text = "us"
          else
            langLabel.text = name.split(/[\s(]/)[0] || "?"
        } catch (e) {}
      }
    }
  }
}
