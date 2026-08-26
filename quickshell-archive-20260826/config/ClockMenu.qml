import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
  id: clockCard

  property var targetScreen: null

  anchors.top: true
  margins.top: 38
  anchors.left: true
  anchors.right: true
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"
  WlrLayershell.namespace: "quickshell"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  property bool shown: false
  property date calDate: new Date()
  property var resVals: []
  screen: clockCard.targetScreen
  visible: clockCard.shown && (!ClockState.screen || ClockState.screen === clockCard.targetScreen)
  implicitWidth: 520
  implicitHeight: col.implicitHeight + 32

  Process { id: focusProc; running: false }
  function focusApp(n) {
    const raw = n ? (n.desktopEntry || n.appName || "") : ""
    if (!raw) return
    const cmd = 'app="' + String(raw).replace(/"/g, '\\"') + '"; id=$(mmsg get all-clients 2>/dev/null | python3 -c "import json,sys; app=sys.argv[1].lower(); data=json.load(sys.stdin); cs=data.get(\'clients\',[]); m=[c for c in cs if app==c.get(\'appid\',\'\').lower() or app in c.get(\'appid\',\'\').lower() or app in c.get(\'title\',\'\').lower()]; print(m[0][\'id\'] if m else \'\')" "$app" 2>/dev/null); [ -n "$id" ] && mmsg dispatch focusid client,$id 2>/dev/null || true'
    focusProc.command = ["bash", "-c", cmd]
    focusProc.running = true
  }

  // system info — stolen from noctalia/ii-eve via FileView (procfs) + df
  property var _prevCpu: null
  FileView { id: statFile; path: "/proc/stat" }
  FileView { id: memFile; path: "/proc/meminfo" }
  Process {
    id: diskProc
    command: ["sh", "-c", "df --output=pcent / 2>/dev/null | tail -1 | tr -d ' %'"]
    stdout: StdioCollector {
      onStreamFinished: {
        const v = text.trim()
        if (v !== "" && !isNaN(parseInt(v))) {
          const cur = clockCard.resVals.slice()
          while (cur.length < 3) cur.push("0")
          cur[2] = String(parseInt(v))
          clockCard.resVals = cur
        }
      }
    }
  }
  Timer {
    id: resTimer
    interval: 2000
    running: clockCard.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      statFile.reload()
      memFile.reload()
      diskProc.running = true
    }
  }
  Connections {
    target: statFile
    function onLoaded() {
      const txt = statFile.text()
      if (!txt) return
      const m = txt.match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/m)
      if (!m) return
      const idle = parseInt(m[4]) + parseInt(m[5])
      const total = m.slice(1,9).reduce((a,b)=>a+parseInt(b),0)
      if (clockCard._prevCpu && clockCard._prevCpu.total > 0) {
        const dTotal = total - clockCard._prevCpu.total
        const dIdle = idle - clockCard._prevCpu.idle
        if (dTotal > 0) {
          const pct = Math.round((1 - dIdle/dTotal)*100)
          const cur = clockCard.resVals.slice()
          while (cur.length < 3) cur.push("0")
          cur[0] = String(Math.max(0, Math.min(100, pct)))
          clockCard.resVals = cur
        }
      }
      clockCard._prevCpu = { total: total, idle: idle }
    }
  }
  Connections {
    target: memFile
    function onLoaded() {
      const txt = memFile.text()
      if (!txt) return
      const tM = txt.match(/MemTotal:\s+(\d+)\s+kB/)
      const aM = txt.match(/MemAvailable:\s+(\d+)\s+kB/)
      if (!tM) return
      const total = parseInt(tM[1])
      let avail = aM ? parseInt(aM[1]) : 0
      if (!aM) {
        const fM = txt.match(/MemFree:\s+(\d+)\s+kB/)
        const bM = txt.match(/Buffers:\s+(\d+)\s+kB/)
        const cM = txt.match(/Cached:\s+(\d+)\s+kB/)
        avail = (fM?parseInt(fM[1]):0)+(bM?parseInt(bM[1]):0)+(cM?parseInt(cM[1]):0)
      }
      if (total > 0) {
        const pct = Math.round((total - avail)/total*100)
        const cur = clockCard.resVals.slice()
        while (cur.length < 3) cur.push("0")
        cur[1] = String(Math.max(0, Math.min(100, pct)))
        clockCard.resVals = cur
      }
    }
  }

  Connections {
    target: ClockState
    function onOpenChanged() {
      if (ClockState.open && (!ClockState.screen || ClockState.screen === clockCard.targetScreen))
        clockCard.shown = true
      else if (!ClockState.open && clockCard.shown && slideOut.running === false)
        slideOut.restart()
    }
  }

  onShownChanged: {
    if (shown) {
      card.y = -card.height - 8
      slideIn.restart()
    }
  }

  NumberAnimation {
    id: slideIn
    target: card
    property: "y"
    to: 0
    duration: 260
    easing.type: Easing.OutCubic
  }

  NumberAnimation {
    id: slideOut
    target: card
    property: "y"
    to: -clockCard.height - 8
    duration: 200
    easing.type: Easing.InCubic
    onFinished: clockCard.shown = false
  }

  Rectangle {
    id: card
    width: 520
    anchors.right: parent.right
    anchors.rightMargin: 8
    height: parent.height
    color: "#000000"
    border.color: "#ffffff"
    border.width: 1

    MouseArea { anchors.fill: parent }

    ColumnLayout {
      id: col
      anchors.fill: parent
      anchors.margins: 8
      spacing: 8

      // top: calendar left + system info right
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        // Calendar — wider, cube cells
        ColumnLayout {
          Layout.preferredWidth: 300
          spacing: 4

          RowLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
              text: "\u25C0"
              color: "#888888"
              font.family: Theme.fontFamily
              font.pixelSize: 11
              Layout.preferredWidth: 28
              Layout.preferredHeight: 22
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  const d = clockCard.calDate
                  clockCard.calDate = new Date(d.getFullYear(), d.getMonth() - 1, 1)
                }
              }
            }
            Item { Layout.fillWidth: true; implicitHeight: monthLabel.implicitHeight
              Text {
                id: monthLabel
                anchors.centerIn: parent
                color: "#ffffff"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                text: clockCard.calDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: clockCard.calDate = new Date()
              }
            }
            Text {
              text: "\u25B6"
              color: "#888888"
              font.family: Theme.fontFamily
              font.pixelSize: 11
              Layout.preferredWidth: 28
              Layout.preferredHeight: 22
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  const d = clockCard.calDate
                  clockCard.calDate = new Date(d.getFullYear(), d.getMonth() + 1, 1)
                }
              }
            }
          }

          DayOfWeekRow {
            Layout.fillWidth: true
            locale: grid.locale
            delegate: Text {
              required property var model
              horizontalAlignment: Text.AlignHCenter
              text: model.shortName.slice(0, 2)
              color: "#555555"
              font.family: Theme.fontFamily
              font.pixelSize: 8
            }
          }

          MonthGrid {
            id: grid
            Layout.fillWidth: true
            month: clockCard.calDate.getMonth()
            year: clockCard.calDate.getFullYear()
            locale: Qt.locale()
            spacing: 2

            delegate: Rectangle {
              required property var model
              // cube
              implicitWidth: 38
              implicitHeight: 38
              color: model.today ? "#ffffff" : "transparent"
              border.color: model.today ? "#ffffff" : "transparent"
              border.width: 0
              Text {
                anchors.centerIn: parent
                text: grid.locale.toString(model.date, "d")
                color: model.today ? "#000000" : (model.month === grid.month ? "#ffffff" : "#333333")
                font.family: Theme.fontFamily
                font.pixelSize: 10
              }
            }
          }
        }

        Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: "#222222" }

        // System info — like caelestia Resources (cpu/mem/disk)
        ColumnLayout {
          Layout.preferredWidth: 170
          Layout.fillHeight: true
          Layout.alignment: Qt.AlignTop
          spacing: 8

          Text {
            text: "SYSTEM"
            color: "#ffffff"
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.letterSpacing: 1
            Layout.alignment: Qt.AlignHCenter
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Layout.alignment: Qt.AlignHCenter

            Repeater {
              model: [
                { label: "CPU",  icon: "\uF4BC", idx: 0 },
                { label: "MEM",  icon: "\uEFC5", idx: 1 },
                { label: "DISK", icon: "\uF0A0", idx: 2 }
              ]
              delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                  Layout.fillWidth: true
                  spacing: 6
                  Text {
                    text: modelData.icon
                    color: "#888888"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                  }
                  Text {
                    text: modelData.label
                    color: "#888888"
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.letterSpacing: 1
                  }
                  Item { Layout.fillWidth: true }
                  Text {
                    text: {
                      const v = clockCard.resVals[modelData.idx]
                      return v !== undefined && v !== "" ? v + "%" : "--"
                    }
                    color: "#ffffff"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                  }
                }

                // circular progress — square canvas so ring is perfect circle
                Item {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 56
                  Canvas {
                    id: ring
                    anchors.centerIn: parent
                    width: 56; height: 56
                    property real pct: {
                      const v = parseInt(clockCard.resVals[modelData.idx] || "0")
                      return Math.max(0, Math.min(100, isNaN(v) ? 0 : v)) / 100
                    }
                    onPctChanged: requestPaint()
                    onPaint: {
                      const ctx = getContext("2d")
                      ctx.clearRect(0, 0, width, height)
                      const cx = width/2, cy = height/2, r = 22, lw = 4
                      ctx.lineWidth = lw
                      ctx.lineCap = "butt"
                      // bg
                      ctx.beginPath()
                      ctx.strokeStyle = "#222222"
                      ctx.arc(cx, cy, r, 0, Math.PI*2)
                      ctx.stroke()
                      // fg
                      if (pct > 0) {
                        ctx.beginPath()
                        ctx.strokeStyle = "#ffffff"
                        ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + Math.PI*2*pct)
                        ctx.stroke()
                      }
                    }
                    Text {
                      anchors.centerIn: parent
                      text: modelData.icon
                      color: "#ffffff"
                      font.family: Theme.fontFamily
                      font.pixelSize: 11
                    }
                  }
                }
              }
            }
          }
          Item { Layout.fillHeight: true }
        }
      }

      Rectangle { Layout.fillWidth: true; height: 1; color: "#222222" }

      // Notifications — centered
      ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        RowLayout {
          Layout.fillWidth: true
          spacing: 8
          Text {
            text: "NOTIFICATIONS"
            color: "#ffffff"
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.letterSpacing: 1
          }
          Item { Layout.fillWidth: true }
          Rectangle {
            visible: NotificationServer.notifications.filter(n => n).length > 0
            implicitWidth: clearText.implicitWidth + 12
            implicitHeight: 18
            color: clearMa.containsMouse ? "#ffffff" : "transparent"
            border.color: "#333333"
            border.width: 1
            Text {
              id: clearText
              anchors.centerIn: parent
              text: "CLEAR"
              color: clearMa.containsMouse ? "#000000" : "#666666"
              font.family: Theme.fontFamily
              font.pixelSize: 8
              font.letterSpacing: 1
            }
            MouseArea {
              id: clearMa
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: NotificationServer.clearAll()
            }
          }
        }

        ListView {
          id: notifList
          Layout.fillWidth: true
          Layout.preferredHeight: NotificationServer.notifications.filter(n => n).length > 0
            ? Math.min(200, NotificationServer.notifications.filter(n => n).length * 52) : 0
          clip: true
          spacing: 4
          interactive: true
          boundsBehavior: Flickable.StopAtBounds
          model: NotificationServer.notifications.filter(n => n).slice().reverse()
          visible: NotificationServer.notifications.filter(n => n).length > 0

          delegate: Rectangle {
            width: notifList.width
            color: "#0a0a0a"
            border.color: "#222222"
            border.width: 1
            height: nRow.implicitHeight + 12

            RowLayout {
              id: nRow
              anchors.fill: parent
              anchors.margins: 6
              spacing: 8

              Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignTop
                visible: {
                  const ic = modelData.appIcon || ""
                  const de = modelData.desktopEntry || ""
                  const im = modelData.image ? String(modelData.image) : ""
                  return im !== "" || ic !== "" || de !== ""
                }
                IconImage {
                  anchors.fill: parent
                  anchors.margins: 1
                  visible: {
                    const im = modelData.image ? String(modelData.image) : ""
                    return !(im !== "" && (im.startsWith("/") || im.startsWith("file://") || im.startsWith("image://")))
                  }
                  source: {
                    const ic = modelData.appIcon || ""
                    if (ic !== "") return Quickshell.iconPath(ic, "dialog-information")
                    const de = modelData.desktopEntry || ""
                    if (de !== "") {
                      const e = DesktopEntries.heuristicLookup(de)
                      if (e && e.icon) return Quickshell.iconPath(e.icon, "dialog-information")
                      return Quickshell.iconPath(de, "dialog-information")
                    }
                    return Quickshell.iconPath("dialog-information", "dialog-information")
                  }
                  implicitSize: 20
                }
                Image {
                  anchors.fill: parent
                  anchors.margins: 1
                  visible: {
                    const im = modelData.image ? String(modelData.image) : ""
                    return im !== "" && (im.startsWith("/") || im.startsWith("file://") || im.startsWith("image://"))
                  }
                  source: modelData.image ? String(modelData.image) : ""
                  fillMode: Image.PreserveAspectCrop
                  sourceSize.width: 40
                  sourceSize.height: 40
                  asynchronous: true
                }
                Rectangle {
                  anchors.fill: parent
                  color: "transparent"
                  border.color: "#222222"
                  border.width: 1
                }
              }

              Column {
                Layout.fillWidth: true
                spacing: 2
                Text {
                  text: (modelData.appName || modelData.desktopEntry || "").toUpperCase()
                  color: "#555555"
                  font.family: Theme.fontFamily
                  font.pixelSize: 8
                  font.letterSpacing: 1
                  elide: Text.ElideRight
                  width: parent.width
                  visible: text !== ""
                }
                Text {
                  text: modelData.summary || ""
                  color: "#ffffff"
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                  elide: Text.ElideRight
                  width: parent.width
                  maximumLineCount: 2
                  wrapMode: Text.Wrap
                }
                Text {
                  text: modelData.body || ""
                  color: "#666666"
                  font.family: Theme.fontFamily
                  font.pixelSize: 9
                  width: parent.width
                  wrapMode: Text.Wrap
                  maximumLineCount: 2
                  elide: Text.ElideRight
                  visible: (modelData.body || "") !== ""
                }
              }

              Rectangle {
                implicitWidth: 14
                implicitHeight: 14
                Layout.alignment: Qt.AlignTop
                color: dMa.containsMouse ? "#ffffff" : "transparent"
                Text {
                  anchors.centerIn: parent
                  text: "x"
                  color: dMa.containsMouse ? "#000000" : "#444444"
                  font.family: Theme.fontFamily
                  font.pixelSize: 9
                  font.bold: true
                }
                MouseArea {
                  id: dMa
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: NotificationServer.dismiss(modelData)
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              z: -1
              onClicked: {
                const live = NotificationServer.getLive(modelData.id)
                const acts = live && live.actions ? live.actions : []
                for (let i = 0; i < acts.length; i++) {
                  const a = acts[i]
                  if (a && (a.identifier === "default" || (a.text || "").toLowerCase() === "view" || (a.text || "").toLowerCase() === "open")) {
                    try { a.invoke() } catch(e) {}
                    break
                  }
                }
                clockCard.focusApp(modelData)
                ClockState.close()
                NotificationServer.dismiss(modelData)
              }
            }
          }
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: "no notifications"
          color: "#444444"
          font.family: Theme.fontFamily
          font.pixelSize: 10
          horizontalAlignment: Text.AlignHCenter
          visible: NotificationServer.notifications.filter(n => n).length === 0
        }
      }
    }
  }
}
