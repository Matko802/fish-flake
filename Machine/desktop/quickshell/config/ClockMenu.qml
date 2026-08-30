import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QMLTermWidget 2.0

PanelWindow {
  id: root

  property var targetScreen: null

  anchors.top: true
  margins.top: 30
  anchors.left: true
  anchors.right: true
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"
  WlrLayershell.namespace: "quickshell"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  property bool shown: false
  property int activeTab: 0
  property date calDate: new Date()
  property int mediaIdx: 0
  // keep mediaIdx in bounds and auto-switch to newest playing
  onMediaIdxChanged: {
    if (mediaIdx < 0) mediaIdx = 0
    if (Mpris.players.values && Mpris.players.values.length > 0 && mediaIdx >= Mpris.players.values.length) mediaIdx = Mpris.players.values.length - 1
    if (Mpris.players.values.length === 0) mediaIdx = 0
  }
  Connections {
    target: Mpris.players
    function onValuesChanged() {
      if (Mpris.players.values && root.mediaIdx >= Mpris.players.values.length) root.mediaIdx = Math.max(0, Mpris.players.values.length - 1)
      // when new audio starts, switch to it if it's playing
      if (Mpris.players.values && Mpris.players.values.length > 0) {
        const last = Mpris.players.values ? Mpris.players.values.length - 1 : -1
        const p = Mpris.players.values[last]
        if (p && p.isPlaying) root.mediaIdx = last
      }
    }
  }

  property var sysVals: ["--", "--", "--", "--"]
  property var cpuHist: []
  property var memHist: []
  property var diskHist: []
  property var gpuHist: []
  property var _prevCpu: null

  screen: root.targetScreen
  visible: root.shown && (!ClockState.screen || ClockState.screen === root.targetScreen)
  implicitWidth: 800
  implicitHeight: 444

  function pushHist(arr, v) {
    let a = arr.slice()
    a.push(Math.max(0, Math.min(100, v)))
    if (a.length > 30) a.shift()
    return a
  }

  Process { id: focusProc; running: false }
  function focusApp(n) {
    const raw = n ? (n.desktopEntry || n.appName || "") : ""
    if (!raw) return
    const cmd = 'app="' + String(raw).replace(/"/g, '\\"') + '"; id=$(mmsg get all-clients 2>/dev/null | python3 -c "import json,sys; app=sys.argv[1].lower(); data=json.load(sys.stdin); cs=data.get(\'clients\',[]); m=[c for c in cs if app==c.get(\'appid\',\'\').lower() or app in c.get(\'appid\',\'\').lower() or app in c.get(\'title\',\'\').lower()]; print(m[0][\'id\'] if m else \'\')" "$app" 2>/dev/null); [ -n "$id" ] && mmsg dispatch focusid client,$id 2>/dev/null || true'
    focusProc.command = ["bash", "-c", cmd]
    focusProc.running = true
  }

  FileView { id: statFile; path: "/proc/stat" }
  FileView { id: memFile; path: "/proc/meminfo" }
  Process {
    id: diskProc
    command: ["sh", "-c", "df --output=pcent / 2>/dev/null | tail -1 | tr -d ' %'"]
    stdout: StdioCollector {
      onStreamFinished: {
        const v = text.trim()
        if (v !== "" && !isNaN(parseInt(v))) {
          const iv = Math.max(0, Math.min(100, parseInt(v)))
          const cur = root.sysVals.slice()
          while (cur.length < 4) cur.push("--")
          cur[2] = String(iv)
          root.sysVals = cur
          root.diskHist = root.pushHist(root.diskHist, iv)
        }
      }
    }
  }
  Process {
    id: gpuProc
    command: ["sh", "-c", "for f in /sys/class/drm/card*/device/gpu_busy_percent; do v=$(cat \"$f\" 2>/dev/null); if [ -n \"$v\" ]; then printf '%s' \"$v\"; break; fi; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        const v = text.trim()
        if (v !== "" && !isNaN(parseInt(v))) {
          const iv = Math.max(0, Math.min(100, parseInt(v)))
          const cur = root.sysVals.slice()
          while (cur.length < 4) cur.push("--")
          cur[3] = String(iv)
          root.sysVals = cur
          root.gpuHist = root.pushHist(root.gpuHist, iv)
        }
      }
    }
  }
  Timer {
    interval: 2000; running: root.visible; repeat: true; triggeredOnStart: true
    onTriggered: { statFile.reload(); memFile.reload(); diskProc.running = true; gpuProc.running = true }
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
      if (root._prevCpu && root._prevCpu.total > 0) {
        const dT = total - root._prevCpu.total
        const dI = idle - root._prevCpu.idle
        if (dT > 0) {
          const iv = Math.max(0, Math.min(100, Math.round((1 - dI/dT)*100)))
          const cur = root.sysVals.slice()
          while (cur.length < 4) cur.push("--")
          cur[0] = String(iv)
          root.sysVals = cur
          root.cpuHist = root.pushHist(root.cpuHist, iv)
        }
      }
      root._prevCpu = { total, idle }
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
        const iv = Math.max(0, Math.min(100, Math.round((total - avail)/total*100)))
        const cur = root.sysVals.slice()
        while (cur.length < 4) cur.push("--")
        cur[1] = String(iv)
        root.sysVals = cur
        root.memHist = root.pushHist(root.memHist, iv)
      }
    }
  }

  Connections {
    target: ClockState
    function onOpenChanged() {
      if (ClockState.open && (!ClockState.screen || ClockState.screen === root.targetScreen))
        root.shown = true
      else if (!ClockState.open && root.shown && !slideOut.running)
        slideOut.restart()
    }
  }
  onShownChanged: {
    if (shown) { card.y = -card.height - 8; slideIn.restart() }
  }
  NumberAnimation { id: slideIn; target: card; property: "y"; to: 4; duration: 250; easing.type: Easing.OutCubic }
  NumberAnimation {
    id: slideOut; target: card; property: "y"; to: -root.height - 8
    duration: 250; easing.type: Easing.InCubic; onFinished: root.shown = false
  }

  MouseArea { anchors.fill: parent; onClicked: ClockState.close() }

  Rectangle {
    id: card
    width: 800
    anchors.horizontalCenter: parent.horizontalCenter
    height: parent.height - 4
    color: Theme.bg
    border.color: Theme.outline
    border.width: 1

    MouseArea { anchors.fill: parent }

    ColumnLayout {
      id: col
      anchors.fill: parent
      anchors.margins: 16
      spacing: 0

      // ===== Tab bar =====
      RowLayout {
        Layout.fillWidth: true
        spacing: 0
        Repeater {
          model: [
            { label: "Calendar", idx: 0 },
            { label: "System",   idx: 1 },
            { label: "Media",    idx: 2 }
          ]
          delegate: Item {
            required property var modelData
            Layout.preferredWidth: 80
            Layout.preferredHeight: 32
            property bool active: root.activeTab === modelData.idx
            Text {
              anchors.centerIn: parent
              text: modelData.label
              color: parent.active ? Theme.fg : Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: 12
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.activeTab = modelData.idx
            }
          }
        }
        Item { Layout.fillWidth: true }
        Rectangle {
          Layout.preferredWidth: 28
          Layout.preferredHeight: 28
          color: dndMa.containsMouse ? Theme.fg : "transparent"
          radius: Theme.rounding
          Text {
            anchors.centerIn: parent
            text: NotificationServer.dnd ? "󰂛" : "󰂚"
            color: dndMa.containsMouse ? Theme.bg : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 14
          }
          MouseArea {
            id: dndMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: NotificationServer.setDnd(!NotificationServer.dnd)
          }
        }
        Rectangle {
          Layout.preferredWidth: 28
          Layout.preferredHeight: 28
          color: coffeeMa.containsMouse ? Theme.fg : "transparent"
          radius: Theme.rounding
          Text {
            anchors.centerIn: parent
            text: IdleManager.stayAwake ? "󰾪" : "󰅶"
            color: coffeeMa.containsMouse ? Theme.bg : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 14
          }
          MouseArea {
            id: coffeeMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: IdleManager.stayAwake = !IdleManager.stayAwake
          }
        }
      }

      // ===== Swipeable content =====
      Item {
        id: swipeContainer
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        Row {
          id: swipeRow
          x: root.activeTab * -(swipeContainer.width)
          Behavior on x {
            NumberAnimation { duration: 200; easing.type: Theme.easingOut }
          }

          // ----- Tab 0: Calendar + Notifications -----
          Item {
            width: swipeContainer.width
            height: swipeContainer.height

            // Calendar â left half
            ColumnLayout {
              anchors.left: parent.left
              anchors.right: parent.horizontalCenter
              anchors.rightMargin: 8
              anchors.top: parent.top
              anchors.topMargin: 16
              anchors.bottom: parent.bottom
              spacing: 8

                RowLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text {
                    text: ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        const d = root.calDate
                        root.calDate = new Date(d.getFullYear(), d.getMonth() - 1, 1)
                      }
                    }
                  }
                  Item { Layout.fillWidth: true; Layout.preferredHeight: 32
                    Text {
                      anchors.centerIn: parent
                      text: root.calDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                      color: Theme.fg
                      font.family: Theme.fontFamily
                      font.pixelSize: 12
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.calDate = new Date()
                    }
                  }
                  Text {
                    text: ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        const d = root.calDate
                        root.calDate = new Date(d.getFullYear(), d.getMonth() + 1, 1)
                      }
                    }
                  }
                }

                RowLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Repeater {
                    model: ["Su","Mo","Tu","We","Th","Fr","Sa"]
                    delegate: Text {
                      text: modelData
                      color: Theme.muted2
                      font.family: Theme.fontFamily
                      font.pixelSize: 9
                      Layout.fillWidth: true
                      Layout.preferredHeight: 24
                      horizontalAlignment: Text.AlignHCenter
                      verticalAlignment: Text.AlignVCenter
                    }
                  }
                }

                MonthGrid {
                  id: grid
                  Layout.fillWidth: true
                  Layout.preferredHeight: implicitHeight
                  month: root.calDate.getMonth()
                  year: root.calDate.getFullYear()
                  locale: Qt.locale()
                  spacing: 0
                  delegate: Item {
                    required property var model
                    implicitWidth: 36
                    implicitHeight: 36
                    Rectangle {
                      anchors.centerIn: parent
                      width: 28; height: 28
                      color: model.today ? Theme.fg : "transparent"
                    }
                    Text {
                      anchors.centerIn: parent
                      text: grid.locale.toString(model.date, "d")
                      color: model.today ? Theme.bg : (model.month === grid.month ? Theme.fg : Theme.muted3)
                      font.family: Theme.fontFamily
                      font.pixelSize: 12
                    }
                  }
                }
              }

              // Notifications â right half
              Item {
                anchors.left: parent.horizontalCenter
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                ColumnLayout {
                  anchors.fill: parent
                  spacing: 8

                RowLayout {
                  Layout.fillWidth: true
                  spacing: 8
                  Text {
                    text: "Notifications"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                  }
                  Item { Layout.fillWidth: true; height: 1 }
                  Text {
                    text: NotificationServer.meaningfulCount > 0
                          ? String(NotificationServer.meaningfulCount) : ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                  }
                  Text {
                    id: clearBtn
                    text: "Clear"
                    color: clearBtnMa.containsMouse ? Theme.fg : Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    visible: NotificationServer.meaningfulCount > 0
                    MouseArea {
                      id: clearBtnMa
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
                  Layout.fillHeight: true
                  clip: true
                  spacing: 4
                  interactive: true
                  boundsBehavior: Flickable.StopAtBounds
                  model: NotificationServer.notifications.filter(n => n && NotificationServer.isMeaningful(n)).slice().reverse()

                  add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Theme.easingOut }
                    NumberAnimation { property: "y"; from: 20; to: 0; duration: 200; easing.type: Theme.easingOut }
                  }
                  remove: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150; easing.type: Theme.easingIn }
                    NumberAnimation { property: "x"; from: 0; to: 40; duration: 150; easing.type: Theme.easingIn }
                  }
                  displaced: Transition {
                    NumberAnimation { property: "y"; duration: 200; easing.type: Theme.easingOut }
                  }
                  delegate: Rectangle {
                    width: notifList.width
                    height: nRow.implicitHeight + 16
                    color: Theme.bgAlt
                    border.color: Theme.border
                    border.width: 1
                    RowLayout {
                      id: nRow
                      anchors.fill: parent
                      anchors.margins: 8
                      spacing: 8
                      Item {
                        Layout.preferredWidth: 20; Layout.preferredHeight: 20; Layout.alignment: Qt.AlignTop
                        visible: {
                          const ic = modelData.appIcon || ""
                          const de = modelData.desktopEntry || ""
                          const im = modelData.image ? String(modelData.image) : ""
                          return im !== "" || ic !== "" || de !== ""
                        }
                        IconImage {
                          anchors.fill: parent; anchors.margins: 1
                          visible: { const im = modelData.image ? String(modelData.image) : ""; return !(im !== "" && (im.startsWith("/") || im.startsWith("file://") || im.startsWith("image://"))) }
                          source: {
                            const ic = modelData.appIcon || ""
                            if (ic !== "") return Quickshell.iconPath(ic, "dialog-information")
                            const de = modelData.desktopEntry || ""
                            if (de !== "") { const e = DesktopEntries.heuristicLookup(de); if (e && e.icon) return Quickshell.iconPath(e.icon, "dialog-information"); return Quickshell.iconPath(de, "dialog-information") }
                            return Quickshell.iconPath("dialog-information", "dialog-information")
                          }
                          implicitSize: 20
                        }
                        Image {
                          anchors.fill: parent; anchors.margins: 1
                          visible: { const im = modelData.image ? String(modelData.image) : ""; return im !== "" && (im.startsWith("/") || im.startsWith("file://") || im.startsWith("image://")) }
                          source: modelData.image ? String(modelData.image) : ""
                          fillMode: Image.PreserveAspectCrop
                          sourceSize.width: 40; sourceSize.height: 40; asynchronous: true
                        }
                      }
                      Column {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: (modelData.appName || modelData.desktopEntry || "").toUpperCase(); color: Theme.muted2; font.family: Theme.fontFamily; font.pixelSize: 8; font.letterSpacing: 1; elide: Text.ElideRight; width: parent.width; visible: text !== "" }
                         Text { text: modelData.summary || ""; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 11; width: parent.width; wrapMode: Text.WordWrap }
                         Text { text: modelData.body || ""; color: Theme.muted; font.family: Theme.fontFamily; font.pixelSize: 9; width: parent.width; wrapMode: Text.WordWrap; visible: (modelData.body || "") !== "" }
                      }
                      Rectangle {
                        Layout.preferredWidth: 14; Layout.preferredHeight: 14; Layout.alignment: Qt.AlignTop
                        color: dMa.containsMouse ? Theme.fg : "transparent"
                        Text { anchors.centerIn: parent; text: "x"; color: dMa.containsMouse ? Theme.bg : Theme.muted2; font.family: Theme.fontFamily; font.pixelSize: 9; font.bold: true }
                        MouseArea { id: dMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: NotificationServer.dismiss(modelData) }
                      }
                    }
                    MouseArea {
                      anchors.fill: parent; cursorShape: Qt.PointingHandCursor; z: -1
                      onClicked: {
                        const live = NotificationServer.getLive(modelData.id)
                        const acts = live && live.actions ? live.actions : []
                        for (let i = 0; i < acts.length; i++) { const a = acts[i]; if (a && (a.identifier === "default" || (a.text || "").toLowerCase() === "view" || (a.text || "").toLowerCase() === "open")) { try { a.invoke() } catch(e) {} break } }
                        root.focusApp(modelData); ClockState.close(); NotificationServer.dismiss(modelData)
                      }
                    }
                  }
                }
                Item {
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                }
                }

                Text {
                  anchors.centerIn: parent
                  text: "no notifications"
                  color: Theme.muted2
                  font.family: Theme.fontFamily
                  font.pixelSize: 10
                   visible: NotificationServer.meaningfulCount === 0
                }
              }
            }

          // ----- Tab 1: System -----
          Item {
            width: swipeContainer.width
            height: swipeContainer.height

            GridLayout {
              anchors.fill: parent
              anchors.margins: 16
              columns: 2
              rowSpacing: 12
              columnSpacing: 12

              Repeater {
                model: [
                  { label: "CPU",  icon: "\uF4BC", idx: 0 },
                  { label: "MEM",  icon: "\uEFC5", idx: 1 },
                  { label: "DISK", icon: "\uF0A0", idx: 2 },
                  { label: "GPU",  icon: "\uF2DB", idx: 3 }
                ]
                delegate: Rectangle {
                  required property var modelData
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  color: Theme.bgAlt
                  border.color: Theme.border
                  border.width: 1
                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                      Layout.fillWidth: true
                      spacing: 0
                      Text { text: modelData.icon + "  " + modelData.label; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 10 }
                      Item { Layout.fillWidth: true; height: 1 }
                      Text {
                        text: { const v = root.sysVals[modelData.idx]; return v !== undefined && v !== "--" ? v + "%" : "--" }
                        color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 11
                      }
                    }

                    Item {
                      Layout.fillWidth: true; Layout.fillHeight: true
                      Canvas {
                        anchors.centerIn: parent; width: 80; height: 80
                        property real pct: { const v = parseInt(root.sysVals[modelData.idx] || "0"); return Math.max(0, Math.min(100, isNaN(v) ? 0 : v)) / 100 }
                        onPctChanged: requestPaint()
                        onPaint: {
                          const ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                          const cx = width/2, cy = height/2, r = 32, lw = 3
                          ctx.lineWidth = lw; ctx.lineCap = "round"
                          ctx.beginPath(); ctx.strokeStyle = Theme.border; ctx.arc(cx, cy, r, 0, Math.PI*2); ctx.stroke()
                          if (pct > 0) { ctx.beginPath(); ctx.strokeStyle = Theme.fg; ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + Math.PI*2*pct); ctx.stroke() }
                        }
                        Text { anchors.centerIn: parent; text: modelData.icon; color: Theme.fg; font.family: Theme.fontFamily; font.pixelSize: 18 }
                      }
                    }

                    Canvas {
                      Layout.fillWidth: true; Layout.preferredHeight: 24
                      property var hist: { if (modelData.idx === 0) return root.cpuHist; if (modelData.idx === 1) return root.memHist; if (modelData.idx === 2) return root.diskHist; return root.gpuHist }
                      onHistChanged: requestPaint()
                      onPaint: {
                        const ctx = getContext("2d"); ctx.clearRect(0, 0, width, height)
                        if (!hist || hist.length < 2) return
                        ctx.strokeStyle = Theme.fg; ctx.lineWidth = 1; ctx.beginPath()
                        for (let i = 0; i < hist.length; i++) {
                          const x = i / Math.max(1, hist.length - 1) * width; const y = height - (hist[i] / 100 * height)
                          if (i === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y)
                        }
                        ctx.stroke()
                      }
                    }
                  }
                }
              }
            }
          }

          // ----- Tab 2: Media -----
          Item {
            width: swipeContainer.width
            height: swipeContainer.height

            ColumnLayout {
              anchors.fill: parent
              spacing: 0



              // Tabbed single player view (arrows next to icon)
              Item {
                id: mediaSingle
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: true
                 property var cur: (Mpris.players.values && Mpris.players.values.length > root.mediaIdx) ? Mpris.players.values[root.mediaIdx] : null
                 ColumnLayout {
                    id: msRoot
                    anchors.fill: parent
                    spacing: 0

                    // BODY
                    RowLayout {
                      id: msBody
                      Layout.fillWidth: true
                      Layout.fillHeight: true
                      spacing: 0

                      // LEFT — info + terminal + controls + progress (always present; grows when expanded)
                       ColumnLayout {
                          id: msLeft
                          Layout.fillWidth: true
                          Layout.fillHeight: true
                          Layout.leftMargin: 16
                          Layout.rightMargin: 16
                          Layout.bottomMargin: 8
                          spacing: 8

                        // title
                        ColumnLayout {
                          visible: true
                          spacing: 8
                          Text {
                            Layout.fillWidth: true
                            Layout.maximumHeight: 44
                            clip: true
                            text: mediaSingle.cur ? (mediaSingle.cur.trackTitle || "Unknown") : "no songs playing"
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            font.bold: true
                            wrapMode: Text.Wrap
                          }
                          Text {
                            Layout.fillWidth: true
                            text: {
                              if (!mediaSingle.cur) return ""
                              const a = mediaSingle.cur.trackArtist || ""
                              const b = mediaSingle.cur.trackAlbum || ""
                              if (a && b) return a + " — " + b
                              return a || b || (mediaSingle.cur.identity || "")
                            }
                            color: Theme.muted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                          }
                        }

                        Rectangle {
                          id: termRect
                          Layout.fillWidth: true
                          Layout.fillHeight: true
                          Layout.preferredHeight: 200
                          color: "#000000"
                          clip: true
                          property bool termRunning: false
                          Timer {
                            interval: 500
                            running: true
                            repeat: true
                            onTriggered: termRect.termRunning = sharkVisSession.hasActiveProcess
                          }
                          QMLTermWidget {
                            id: sharkVisTerm
                            anchors.fill: parent
                            font.family: Theme.fontFamily
                            font.pointSize: 9
                            colorScheme: "Linux"
                            focus: false
                            enabled: true
                            session: QMLTermSession {
                              id: sharkVisSession
                              shellProgram: "/etc/profiles/per-user/matko/bin/sharkvis"
                            }
                            function startProg(prog, args) {
                              if (sharkVisSession.hasActiveProcess) return
                              sharkVisSession.shellProgram = prog
                              sharkVisSession.shellProgramArgs = args
                              sharkVisSession.startShellProgram()
                            }
                            Component.onCompleted: {
                              if (root.shown) sharkVisTerm.startProg("/etc/profiles/per-user/matko/bin/sharkvis", [])
                            }
                            Connections {
                              target: sharkVisSession
                              function onFinished() {
                                if (root.shown) sharkVisTerm.startProg("bash", [])
                              }
                            }
                            Connections {
                              target: root
                              function onShownChanged() {
                                if (root.shown) {
                                  sharkVisTerm.startProg("/etc/profiles/per-user/matko/bin/sharkvis", [])
                                } else if (sharkVisSession.hasActiveProcess) {
                                  sharkVisSession.sendSignal(15)
                                }
                              }
                            }
                          }
                          MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                            cursorShape: Qt.IBeamCursor
                            onEntered: sharkVisTerm.forceActiveFocus()
                            onExited: sharkVisTerm.focus = false
                          }
                        }

                        // transport controls
                        Rectangle {
                          Layout.alignment: Qt.AlignHCenter
                          Layout.topMargin: -8
                          implicitWidth: 146
                          implicitHeight: 46
                          color: Theme.bgAlt
                          border.color: Theme.border
                          border.width: 1
                          RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            Item {
                              Layout.preferredWidth: 44
                              Layout.fillHeight: true
                              Text {
                                anchors.centerIn: parent
                                text: "⏮"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 20
                              }
                              MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (mediaSingle.cur) mediaSingle.cur.previous()
                              }
                            }
                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.border }
                            Item {
                              Layout.preferredWidth: 56
                              Layout.fillHeight: true
                              Text {
                                anchors.centerIn: parent
                                text: mediaSingle.cur && mediaSingle.cur.isPlaying ? "⏸" : "▶"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 26
                              }
                              MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (mediaSingle.cur) mediaSingle.cur.togglePlaying()
                              }
                            }
                            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: Theme.border }
                            Item {
                              Layout.preferredWidth: 44
                              Layout.fillHeight: true
                              Text {
                                anchors.centerIn: parent
                                text: "⏭"
                                color: Theme.fg
                                font.family: Theme.fontFamily
                                font.pixelSize: 20
                              }
                              MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (mediaSingle.cur) mediaSingle.cur.next()
                              }
                            }
                          }
                        }

                        Rectangle {
                          id: progressBar
                          Layout.alignment: Qt.AlignHCenter
                          Layout.topMargin: 6
                          implicitWidth: 260
                          Layout.preferredHeight: 22
                          color: "transparent"
                          visible: mediaSingle.cur && mediaSingle.cur.lengthSupported
                          property bool hovered: false
                          property bool scrubbing: false
                          function fmtTime(t) {
                            if (!t || t < 0) t = 0
                            const m = Math.floor(t / 60)
                            const s = Math.floor(t % 60)
                            return m + ":" + (s < 10 ? "0" : "") + s
                          }
                          function seek(x) {
                            if (mediaSingle.cur && mediaSingle.cur.positionSupported)
                              mediaSingle.cur.position = (x / width) * mediaSingle.cur.length
                          }
                          Rectangle {
                            id: progBox
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: progressBar.hovered ? parent.width : 200
                            height: progressBar.hovered ? 14 : 8
                            color: progressBar.hovered ? Theme.bgAlt : Theme.border
                            border.color: Theme.border
                            border.width: progressBar.hovered ? 1 : 0
                            clip: true
                            property real fillW: width * Math.max(0, Math.min(1, mediaSingle.cur ? mediaSingle.cur.position / Math.max(1, mediaSingle.cur.length) : 0))
                            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                            Rectangle {
                              z: 0
                              anchors.left: parent.left
                              anchors.verticalCenter: parent.verticalCenter
                              height: progressBar.hovered ? 8 : 6
                              width: parent.width * Math.max(0, Math.min(1, (mediaSingle.cur ? mediaSingle.cur.position / Math.max(1, mediaSingle.cur.length) : 0)))
                              color: Theme.fg
                            }
                          }
                          Text {
                            z: 1
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: progressBar.fmtTime(mediaSingle.cur ? mediaSingle.cur.position : 0)
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            visible: progressBar.hovered
                          }
                          Item {
                            z: 2
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: progBox.fillW
                            clip: true
                            visible: progressBar.hovered
                            Text {
                              anchors.left: parent.left
                              anchors.leftMargin: 6
                              anchors.verticalCenter: parent.verticalCenter
                              text: progressBar.fmtTime(mediaSingle.cur ? mediaSingle.cur.position : 0)
                              color: Theme.bg
                              font.family: Theme.fontFamily
                              font.pixelSize: 9
                            }
                          }
                          Text {
                            z: 1
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: progressBar.fmtTime(mediaSingle.cur ? mediaSingle.cur.length : 0)
                            color: Theme.fg
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            visible: progressBar.hovered
                          }
                          Item {
                            z: 2
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: progBox.fillW
                            clip: true
                            visible: progressBar.hovered
                            Text {
                              x: progBox.width - 6 - width
                              anchors.verticalCenter: parent.verticalCenter
                              text: progressBar.fmtTime(mediaSingle.cur ? mediaSingle.cur.length : 0)
                              color: Theme.bg
                              font.family: Theme.fontFamily
                              font.pixelSize: 9
                            }
                          }
                          MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: progressBar.hovered = true
                            onExited: progressBar.hovered = false
                            onPressed: mouse => { progressBar.scrubbing = true; progressBar.seek(mouse.x) }
                            onReleased: progressBar.scrubbing = false
                            onPositionChanged: mouse => { if (progressBar.scrubbing) progressBar.seek(mouse.x) }
                          }
                        }
                      }

                      // RIGHT — artwork with tab arrows
                      Item {
                        id: msRight
                        visible: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: swipeContainer.width * 0.46
                        Layout.fillWidth: false
                        clip: true
                        Image {
                          anchors.fill: parent
                          source: mediaSingle.cur && mediaSingle.cur.trackArtUrl ? mediaSingle.cur.trackArtUrl : ""
                          fillMode: Image.PreserveAspectCrop
                          asynchronous: true
                          visible: !!(mediaSingle.cur && mediaSingle.cur.trackArtUrl)
                        }
                        AnimatedImage {
                          anchors.fill: parent
                          source: "file:///mnt/ssd/My-Files/Pictures/animated%20shark.gif"
                          fillMode: Image.PreserveAspectCrop
                          playing: true
                          cache: false
                          visible: !(mediaSingle.cur && mediaSingle.cur.trackArtUrl)
                        }
                        Item {
                          id: tabContainer
                          anchors.bottom: parent.bottom
                          anchors.horizontalCenter: parent.horizontalCenter
                          anchors.bottomMargin: 6
                          width: tabRow.implicitWidth + 12
                          height: (tabHover.containsMouse) ? 16 : 10
                          visible: Mpris.players.values && Mpris.players.values.length > 1
                          Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                          Rectangle {
                            anchors.fill: parent
                            color: (tabHover.containsMouse) ? Theme.bgAlt : "transparent"
                            border.color: Theme.border
                            border.width: (tabHover.containsMouse) ? 1 : 0
                            radius: 0
                          }
                          RowLayout {
                            id: tabRow
                            anchors.centerIn: parent
                            spacing: (tabHover.containsMouse) ? 2 : 4
                            Repeater {
                              model: Mpris.players.values ? Mpris.players.values.length : 0
                              delegate: Rectangle {
                                required property int index
                                implicitWidth: (tabHover.containsMouse) ? (index === root.mediaIdx ? 18 : 10) : 6
                                implicitHeight: (tabHover.containsMouse) ? 8 : 6
                                radius: 0
                                color: index === root.mediaIdx ? Theme.fg : Theme.muted2
                                Behavior on implicitWidth { NumberAnimation { duration: 120 } }
                                Behavior on implicitHeight { NumberAnimation { duration: 120 } }
                                MouseArea {
                                  anchors.fill: parent
                                  cursorShape: Qt.PointingHandCursor
                                  onClicked: root.mediaIdx = index
                                }
                              }
                            }
                          }
                          MouseArea {
                            id: tabHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                          }
                        }
                      }
                    }
                  }
              }

            }
          }

        }
      }
    }
  }
}
