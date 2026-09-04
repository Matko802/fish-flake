import QtQuick
import Quickshell
import Quickshell.Io

Text {
  id: langLabel
  text: "?"
  color: "#ffffff"
  font.pixelSize: 12

  // Niri: keyboard-layouts via niri msg (JSON)
  Process {
    id: niriInit
    running: true
    command: ["sh", "-c", "command -v niri >/dev/null 2>&1 && niri msg -j keyboard-layouts 2>/dev/null || echo ''"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const d = JSON.parse(data)
          const idx = d.current_idx ?? 0
          const names = d.names || []
          const cur = String(names[idx] || "").toLowerCase()
          if (cur.startsWith("slovak")) langLabel.text = "sk"
          else if (cur.startsWith("english")) langLabel.text = "us"
          else langLabel.text = cur.split(/[\s(]/)[0] || "?"
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
          if (!k) return
          const idx = k.current_idx ?? 0
          const names = k.names || []
          const cur = String(names[idx] || "").toLowerCase()
          if (cur.startsWith("slovak")) langLabel.text = "sk"
          else if (cur.startsWith("english")) langLabel.text = "us"
          else langLabel.text = cur.split(/[\s(]/)[0] || "?"
        } catch (e) {}
      }
    }
  }

  // Mango fallback: mmsg watch keyboardlayout
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
