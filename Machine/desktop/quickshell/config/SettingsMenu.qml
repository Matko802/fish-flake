import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire

Scope {
  id: root

  signal choose(string action)

  property bool open: false
  property int selIdx: 0
  property int hoverIdx: -1
  property int activeTab: 0
  readonly property string fontFamily: Theme.fontFamily
  readonly property var tabs: ["Appearance", "Audio"]
  readonly property int tabW: 130
  readonly property int contentW: 340

  readonly property var appearanceItems: [
    { name: "Wallpaper", glyph: "wallpaper", action: "wallpaper" },
    { name: "Launcher",  glyph: "search", action: "launcher" },
    { name: "Profile picture", glyph: "user-circle", action: "avatar" }
  ]

  // Cycle the live icon theme (wraps around); Theme.iconTheme change reloads all QIcon.
  function cycleIconTheme(dir) {
    const list = Theme.iconThemes
    if (!list || list.length === 0)
      return
    let i = list.indexOf(Theme.iconTheme)
    if (i < 0) i = 0
    const nxt = (i + dir + list.length) % list.length
    Theme.iconTheme = list[nxt]
  }

  readonly property var sources: Pipewire.nodes.values
    .filter(n => n && n.audio && !n.isStream && !n.isSink)
    .map(n => ({ id: n.id, name: String(n.name), desc: String(n.description || n.name) }))
  readonly property var sinks: Pipewire.nodes.values
    .filter(n => n && n.audio && !n.isStream && n.isSink)
    .map(n => ({ id: n.id, name: String(n.name), desc: String(n.description || n.name) }))

  // Reactive default detection (node.isDefault is not reactive, but these are).
  function isDefaultSink(id) {
    return Pipewire.defaultAudioSink != null && Pipewire.defaultAudioSink.id === id
  }
  function isDefaultSource(id) {
    return Pipewire.defaultAudioSource != null && Pipewire.defaultAudioSource.id === id
  }

  // The model index IS the selection index (headers included), so we don't use a
  // separate gi counter — activating by model index always hits the right row.
  readonly property var audioModel: {
    const arr = []
    arr.push({ header: true, label: "INPUT  ·  MICROPHONE" })
    for (const s of root.sources) arr.push({ header: false, id: s.id, desc: s.desc, name: s.name, def: root.isDefaultSource(s.id), type: "source" })
    arr.push({ header: true, label: "OUTPUT  ·  SPEAKERS" })
    for (const k of root.sinks) arr.push({ header: false, id: k.id, desc: k.desc, name: k.name, def: root.isDefaultSink(k.id), type: "sink" })
    return arr
  }

  readonly property var currentItems: root.activeTab === 0 ? root.appearanceItems : root.audioModel

  property bool closePending: false

  function requestClose() {
    if (!root.open || root.closePending)
      return
    root.closePending = true
    closeTimer.restart()
  }

  function forceClose() {
    closeTimer.stop()
    root.closePending = false
    root.open = false
  }

  Timer {
    id: closeTimer
    interval: 250
    onTriggered: {
      root.open = false
      closeCleanTimer.restart()
    }
  }

  Timer {
    id: closeCleanTimer
    interval: 250
    onTriggered: {
      root.closePending = false
    }
  }

  function toggle() {
    if (root.open) {
      root.requestClose()
      return
    }
    closeTimer.stop()
    root.closePending = false
    root.open = true
    root.activeTab = 0
    root.selIdx = 0
    root.hoverIdx = -1
  }

  IpcHandler {
    target: "settings"
    function toggle() { root.toggle() }
    function close() { root.forceClose() }
  }

  onActiveTabChanged: { root.selIdx = 0; root.hoverIdx = -1; root.skipHeader(1) }
  onCurrentItemsChanged: {
    if (root.selIdx >= root.currentItems.length)
      root.selIdx = Math.max(0, root.currentItems.length - 1)
  }

  function skipHeader(dir) {
    const items = root.currentItems
    let guard = 0
    while (root.selIdx >= 0 && root.selIdx < items.length && items[root.selIdx] && items[root.selIdx].header && guard++ < 50)
      root.selIdx += dir
    if (root.selIdx < 0) root.selIdx = 0
    if (root.selIdx >= items.length) root.selIdx = items.length - 1
  }

  function activate(i) {
    const item = root.currentItems[i]
    if (!item || item.header)
      return
    if (root.activeTab === 0) {
      root.forceClose()
      root.choose(item.action)
    } else {
      root.selIdx = i
      if (item.type === "source")
        Audio.setDefaultSource(item.id)
      else
        Audio.setDefaultSink(item.id)
    }
  }

  readonly property int boxWidth: root.tabW + root.contentW + 18
  readonly property int boxHeight: 460

  // Noctalia-style window (not overlay) — regular toplevel, centered
  FloatingWindow {
    id: settingsWindow
    visible: root.open || root.closePending
    implicitWidth: root.boxWidth
    implicitHeight: root.boxHeight
    color: "transparent"
    title: "SharkShell Settings"

      Rectangle {
      id: card
      anchors.fill: parent
      color: "#000000"
      border.color: "transparent"
      border.width: 1
      opacity: root.open ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 150; easing.type: Theme.easingOut } }

      RowLayout {
        anchors.fill: parent
        spacing: 0

        // ===== Tab sidebar =====
        ColumnLayout {
          Layout.preferredWidth: root.tabW
          Layout.fillHeight: true
          spacing: 0

          Repeater {
            model: root.tabs
            delegate: Rectangle {
              required property var modelData
              required property int index
              width: root.tabW
              Layout.fillWidth: true
              Layout.preferredHeight: 40
              color: root.activeTab === index ? "#ffffff" : (root.hoverIdx === -2 - index ? "#33ffffff" : "transparent")
              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoverIdx = -2 - index
                onExited: { if (root.hoverIdx === -2 - index) root.hoverIdx = -1 }
                onClicked: { root.activeTab = index; root.selIdx = 0 }
              }
              Text {
                anchors.centerIn: parent
                text: modelData
                color: root.activeTab === index ? "#000000" : "#ffffff"
                font.family: root.fontFamily
                font.pixelSize: 12
              }
            }
          }
          Item { Layout.fillHeight: true }
        }

        Rectangle {
          Layout.fillHeight: true
          width: 1
          color: "#333333"
        }

        // ===== Content =====
        Item {
          Layout.preferredWidth: root.contentW
          Layout.fillHeight: true
          clip: true

          Flickable {
            anchors.fill: parent
            anchors.margins: 12
            contentHeight: contentCol.height
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
              id: contentCol
              anchors.left: parent.left
              anchors.right: parent.right
              spacing: 8

              Text {
                text: root.activeTab === 0 ? "Appearance" : "Audio"
                color: "#ffffff"
                font.family: root.fontFamily
                font.pixelSize: 13
                font.letterSpacing: 1
              }

              // ----- Appearance tab -----
              ColumnLayout {
                visible: root.activeTab === 0
                Layout.fillWidth: true
                spacing: 4
                Repeater {
                  model: root.appearanceItems
                  delegate: Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: root.selIdx === index ? "#ffffff" : (root.hoverIdx === index ? "#33ffffff" : "transparent")
                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onEntered: root.hoverIdx = index
                      onExited: { if (root.hoverIdx === index) root.hoverIdx = -1 }
                      onClicked: root.activate(index)
                    }
                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: 14
                      anchors.rightMargin: 14
                      spacing: 12
                      Item { Layout.preferredWidth: 22; Layout.preferredHeight: 22; QIcon { anchors.centerIn: parent; name: modelData.glyph; size: 22; color: root.selIdx === index ? "#000000" : "#ffffff" } }
                      Text { text: modelData.name; color: root.selIdx === index ? "#000000" : "#ffffff"; font.family: root.fontFamily; font.pixelSize: 12 }
                    }
                  }
                }
              }

              // Current profile picture preview + clear.
              RowLayout {
                visible: root.activeTab === 0
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 10
                Rectangle {
                  Layout.preferredWidth: 44
                  Layout.preferredHeight: 44
                  radius: 22
                  clip: true
                  color: "#111111"
                  border.color: "#ffffff"
                  border.width: 1
                  Image {
                    anchors.fill: parent
                    source: AvatarState.path !== "" ? "file://" + AvatarState.path.split("/").map(encodeURIComponent).join("/") : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    smooth: true
                  }
                  Text {
                    anchors.centerIn: parent
                    visible: AvatarState.path === ""
                    text: "?"
                    color: "#666666"
                    font.family: root.fontFamily
                    font.pixelSize: 18
                  }
                }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2
                  Text {
                    Layout.fillWidth: true
                    text: AvatarState.path !== "" ? AvatarState.path.split("/").pop() : "No profile picture"
                    color: "#ffffff"
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideMiddle
                  }
                  Text {
                    Layout.fillWidth: true
                    visible: AvatarState.path !== ""
                    text: "Shown on lockscreen"
                    color: "#777777"
                    font.family: root.fontFamily
                    font.pixelSize: 9
                  }
                }
                Rectangle {
                  Layout.preferredWidth: 64
                  Layout.preferredHeight: 26
                  radius: 3
                  color: avatarChooseMa.containsMouse ? "#ffffff" : "transparent"
                  border.color: "#ffffff"
                  border.width: 1
                  Text {
                    anchors.centerIn: parent
                    text: "Choose"
                    color: avatarChooseMa.containsMouse ? "#000000" : "#ffffff"
                    font.family: root.fontFamily
                    font.pixelSize: 11
                  }
                  MouseArea {
                    id: avatarChooseMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.choose("avatar")
                  }
                }
                Rectangle {
                  Layout.preferredWidth: 64
                  Layout.preferredHeight: 26
                  radius: 3
                  color: avatarClearMa.containsMouse ? "#ffffff" : "transparent"
                  border.color: "#ffffff"
                  border.width: 1
                  visible: AvatarState.path !== ""
                  Text {
                    anchors.centerIn: parent
                    text: "Clear"
                    color: avatarClearMa.containsMouse ? "#000000" : "#ffffff"
                    font.family: root.fontFamily
                    font.pixelSize: 11
                  }
                  MouseArea {
                    id: avatarClearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AvatarState.clear()
                  }
                }
              }

              // Icon theme selector: cycles the live icon theme (no rebuild).
              RowLayout {
                visible: root.activeTab === 0
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 8
                Text {
                  text: "Icon theme"
                  color: "#8a8a8a"
                  font.family: root.fontFamily
                  font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
                Item {
                  Layout.preferredWidth: 22; Layout.preferredHeight: 22
                  Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: themePrevMa.containsMouse ? "#33ffffff" : "transparent"
                    Text { anchors.centerIn: parent; text: "<"; color: "#ffffff"; font.family: root.fontFamily; font.pixelSize: 12 }
                  }
                  MouseArea { id: themePrevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleIconTheme(-1) }
                }
                Text {
                  text: Theme.iconTheme
                  color: "#ffffff"
                  font.family: root.fontFamily
                  font.pixelSize: 11
                }
                Item {
                  Layout.preferredWidth: 22; Layout.preferredHeight: 22
                  Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: themeNextMa.containsMouse ? "#33ffffff" : "transparent"
                    Text { anchors.centerIn: parent; text: ">"; color: "#ffffff"; font.family: root.fontFamily; font.pixelSize: 12 }
                  }
                  MouseArea { id: themeNextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.cycleIconTheme(1) }
                }
              }

              // ----- Audio tab -----
              ColumnLayout {
                visible: root.activeTab === 1
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                  model: root.audioModel
                  delegate: audioRowComp
                }
              }
            }
          }
        }
      }
    }

    Component {
      id: audioRowComp
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: modelData.header ? 26 : 50
        color: (!modelData.header && root.selIdx === index) ? "#ffffff"
             : ((!modelData.header && root.hoverIdx === index) ? "#33ffffff" : "transparent")
        border.color: (!modelData.header && root.selIdx === index) ? "#000000"
             : ((!modelData.header && modelData.def) ? "#ffffff" : "transparent")
        border.width: (!modelData.header && (root.selIdx === index || modelData.def)) ? 1 : 0
        MouseArea {
          anchors.fill: parent
          enabled: !modelData.header
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: root.hoverIdx = index
          onExited: { if (root.hoverIdx === index) root.hoverIdx = -1 }
          onClicked: root.activate(index)
        }
        RowLayout {
          anchors.fill: parent
          visible: !modelData.header
          anchors.leftMargin: 14
          anchors.rightMargin: 14
          anchors.topMargin: 7
          anchors.bottomMargin: 7
          spacing: 12
          Item {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            QIcon {
              anchors.centerIn: parent
              name: modelData.type === "source" ? "mic" : "audio-volume-high"
              size: 22
              color: root.selIdx === index ? "#000000" : "#ffffff"
            }
          }
          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2
            Text {
              Layout.fillWidth: true
              text: modelData.header ? "" : modelData.desc
              color: root.selIdx === index ? "#000000" : "#ffffff"
              font.family: root.fontFamily
              font.pixelSize: 12
              elide: Text.ElideRight
            }
            Text {
              Layout.fillWidth: true
              text: modelData.header ? "" : modelData.name
              color: root.selIdx === index ? "#333333" : "#777777"
              font.family: root.fontFamily
              font.pixelSize: 9
              elide: Text.ElideRight
            }
          }
        }
        Text {
          visible: modelData.header
          anchors.left: parent.left
          anchors.leftMargin: 2
          anchors.verticalCenter: parent.verticalCenter
          text: modelData.label
          color: "#888888"
          font.family: root.fontFamily
          font.pixelSize: 10
          font.letterSpacing: 2
        }
      }
    }

    Item {
      id: kbFocus
      anchors.fill: parent
      focus: true
      Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) { root.requestClose(); event.accepted = true; return }
        if (event.key === Qt.Key_Tab) {
          root.activeTab = (root.activeTab + 1) % root.tabs.length
          root.selIdx = 0
          root.skipHeader(1)
          event.accepted = true
          return
        }
        if (event.key === Qt.Key_Backtab) {
          root.activeTab = (root.activeTab - 1 + root.tabs.length) % root.tabs.length
          root.selIdx = 0
          root.skipHeader(1)
          event.accepted = true
          return
        }
        if (event.key === Qt.Key_Up) { root.selIdx = Math.max(0, root.selIdx - 1); root.skipHeader(-1); event.accepted = true }
        else if (event.key === Qt.Key_Down) { root.selIdx = Math.min(root.currentItems.length - 1, root.selIdx + 1); root.skipHeader(1); event.accepted = true }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.activate(root.selIdx); event.accepted = true }
      }
    }
  }
}
