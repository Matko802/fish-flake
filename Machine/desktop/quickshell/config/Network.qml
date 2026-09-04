pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: root

  property string kind: "off"
  property int sig: 0
  property string ssid: ""
  property bool wifiEnabled: false
  property string iface: ""
  property real downRate: 0
  property real upRate: 0

  property var networks: []
  property bool scanning: false
  property string connecting: ""
  property string lastError: ""
  property bool expanded: false

  readonly property bool online: kind === "eth" || kind === "wifi"
  readonly property string icon: {
    if (kind === "eth")
      return "network-wired"
    if (kind === "wifi")
      return sigIcon(sig)
    return "wifi-off"
  }

  function sigIcon(s) {
    // Map signal strength 0-100 to a discrete wifi icon name using the catalog levels.
    const names = ["wifi-none", "wifi-weak", "wifi-ok", "wifi-good", "wifi-excellent"]
    let idx = Math.floor(s / 20)
    idx = Math.min(4, Math.max(0, idx))
    if (s >= 100) idx = 4
    else if (s === 0) idx = 0
    return names[idx]
  }

  // Waybar-style "{bandwidthDownBytes} B/s" formatting.
  function fmtRate(r) {
    r = Math.max(0, Math.round(r))
    if (r < 1024)
      return r + " B/s"
    if (r < 1048576)
      return (r / 1024).toFixed(1) + " KiB/s"
    return (r / 1048576).toFixed(1) + " MiB/s"
  }

  readonly property string tooltip: {
    if (kind === "wifi")
      return (ssid || "wifi") + " (" + sig + "%)\n↓ " + fmtRate(downRate) + "  ↑ " + fmtRate(upRate)
    if (kind === "eth")
      return (iface || "ethernet") + "\n↓ " + fmtRate(downRate) + "  ↑ " + fmtRate(upRate)
    return "no network"
  }

  function toggleWifi() {
    const target = root.wifiEnabled ? "off" : "on"
    console.log("[net] toggling wifi radio:", target)
    toggleProc.command = ["/run/current-system/sw/bin/nmcli", "radio", "wifi", target]
    toggleProc.running = true
    if (!root.wifiEnabled)
      scanTimer.restart()
  }

  Process {
    id: toggleProc
    onExited: ok => console.log("[net] toggle exit code:", ok)
    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text.trim() !== "")
          console.log("[net] toggle stderr:", this.text.trim())
      }
    }
  }

  function scan() {
    if (!root.wifiEnabled)
      return
    root.scanning = true
    if (scanProc.running)
      scanProc.running = false
    scanProc.running = true
  }

  function connectTo(ssid, password) {
    if (root.connecting !== "")
      return
    root.lastError = ""
    root.connecting = ssid
    connProc.command = password ? ["nmcli", "device", "wifi", "connect", ssid, "password", password] : ["nmcli", "device", "wifi", "connect", ssid]
    connProc.running = true
  }

  function reportConnectDone(ok) {
    const was = root.connecting
    root.connecting = ""
    if (!ok)
      root.lastError = "failed to connect to " + was
    errTimer.restart()
    scanTimer.restart()
  }

  Timer {
    id: errTimer
    interval: 3000
    onTriggered: root.lastError = ""
  }

  Timer {
    id: scanTimer
    interval: 800
    onTriggered: root.scan()
  }

  Process {
    id: scanProc
    command: ["nmcli", "-t", "-e", "no", "-f", "in-use,signal,security,ssid", "device", "wifi", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        const seen = {}
        const list = []
        this.text.split("\n").forEach(line => {
          if (!line.trim())
            return
          const p = line.split(":")
          if (p.length < 3)
            return
          const inUse = p[0] === "*"
          const signal = parseInt(p[1]) || 0
          const secure = (p[2] || "").trim() !== ""
          const name = p.slice(3).join(":")
          if (!name)
            return
          if (seen[name] !== undefined) {
            if (signal > seen[name].sig) {
              seen[name].sig = signal
              seen[name].secure = seen[name].secure || secure
            }
            seen[name].active = seen[name].active || inUse
            return
          }
          const obj = {
            "ssid": name,
            "sig": signal,
            "secure": secure,
            "active": inUse
          }
          seen[name] = obj
          list.push(obj)
        })
        list.sort((a, b) => (b.active - a.active) || (b.sig - a.sig))
        root.networks = list
        root.scanning = false
      }
    }
  }

  Process {
    id: connProc
    onExited: ok => root.reportConnectDone(ok === 0)
  }

  onExpandedChanged: {
    if (root.expanded)
      root.scan()
  }

  Process {
    id: watcher
    running: true
    command: ["stdbuf", "-oL", "sh", "-c", "L=\"\"; PR=-1; PT=-1; while :; do R=$(nmcli radio wifi 2>/dev/null); K=off; S=0; N=\"\"; IF=\"\"; if nmcli -t -f TYPE,STATE device status 2>/dev/null | grep -q '^ethernet:connected'; then K=eth; IF=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$2==\"ethernet\"&&$3==\"connected\"{print $1; exit}'); else L2=$(nmcli -t -f in-use,signal,ssid dev wifi 2>/dev/null | grep '^\\*' | head -n1); if [ -n \"$L2\" ]; then K=wifi; S=$(printf '%s' \"$L2\" | cut -d: -f2); N=$(printf '%s' \"$L2\" | cut -d: -f3-); IF=$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$2==\"wifi\"&&$3==\"connected\"{print $1; exit}'); fi; fi; RX=$(cat /sys/class/net/$IF/statistics/rx_bytes 2>/dev/null || echo 0); TX=$(cat /sys/class/net/$IF/statistics/tx_bytes 2>/dev/null || echo 0); DN=0; UP=0; if [ -n \"$IF\" ] && [ \"$PR\" -ge 0 ]; then DN=$((RX-PR)); UP=$((TX-PT)); fi; [ $DN -lt 0 ] && DN=0; [ $UP -lt 0 ] && UP=0; PR=$RX; PT=$TX; V=\"kind:$K|sig:$S|ssid:$N|radio:$R|if:$IF|dn:$DN|up:$UP\"; if [ \"$V\" != \"$L\" ]; then printf '%s\\n' \"$V\"; L=\"$V\"; fi; sleep 1; done"]
    stdout: SplitParser {
      onRead: data => {
        let k = "off", s = 0, n = "", r = "", ifn = "", dn = 0, up = 0
        data.split("|").forEach(seg => {
          const i = seg.indexOf(":")
          if (i < 0)
            return
          const key = seg.slice(0, i)
          const val = seg.slice(i + 1)
          if (key === "kind") k = val
          else if (key === "sig") s = parseInt(val) || 0
          else if (key === "ssid") n = val
          else if (key === "radio") r = val
          else if (key === "if") ifn = val
          else if (key === "dn") dn = parseInt(val) || 0
          else if (key === "up") up = parseInt(val) || 0
        })
        root.kind = k
        root.sig = s
        root.ssid = n
        root.wifiEnabled = r.trim() === "enabled"
        root.iface = ifn
        root.downRate = dn
        root.upRate = up
      }
    }
  }
}
