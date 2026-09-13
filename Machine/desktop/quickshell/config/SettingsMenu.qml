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
  property bool closePending: false
  property int activeTab: 0
  property int selIdx: 0
  property int hoverIdx: -1
  property int hoverTab: -1
  readonly property string fontFamily: Theme.fontFamily

  readonly property var tabs: [
    { name: "Theme", glyph: "wallpaper" },
    { name: "Sound", glyph: "audio-volume-high" },
    { name: "User", glyph: "user-circle" }
  ]

  readonly property var themeItems: [
    { name: "Wallpaper", glyph: "wallpaper", action: "wallpaper", hint: "Set desktop wallpaper" }
  ]

  function cycleIconTheme(dir) {
    const list = Theme.iconThemes
    if (!list || list.length === 0)
      return
    let i = list.indexOf(Theme.iconTheme)
    if (i < 0) i = 0
    Theme.iconTheme = list[(i + dir + list.length) % list.length]
  }

  readonly property var sources: Pipewire.nodes.values
    .filter(n => n && n.audio && !n.isStream && !n.isSink)
    .map(n => ({ id: n.id, name: String(n.name), desc: String(n.description || n.name) }))
  readonly property var sinks: Pipewire.nodes.values
    .filter(n => n && n.audio && !n.isStream && n.isSink)
    .map(n => ({ id: n.id, name: String(n.name), desc: String(n.description || n.name) }))

  function isDefaultSink(id) {
    return Pipewire.defaultAudioSink != null && Pipewire.defaultAudioSink.id === id
  }
  function isDefaultSource(id) {
    return Pipewire.defaultAudioSource != null && Pipewire.defaultAudioSource.id === id
  }

  readonly property var audioModel: {
    const arr = []
    arr.push({ header: true, label: "INPUT" })
    for (const s of root.sources) arr.push({ header: false, id: s.id, desc: s.desc, name: s.name, def: root.isDefaultSource(s.id), type: "source" })
    arr.push({ header: true, label: "OUTPUT" })
    for (const k of root.sinks) arr.push({ header: false, id: k.id, desc: k.desc, name: k.name, def: root.isDefaultSink(k.id), type: "sink" })
    return arr
  }

  readonly property var currentItems: root.activeTab === 0 ? root.themeItems : root.audioModel

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
    onTriggered: root.closePending = false
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
    root.hoverTab = -1
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

  FloatingWindow {
    id: settingsWindow
    visible: root.open || root.closePending
    implicitWidth: 542
    implicitHeight: 500
    color: "transparent"
    title: "Settings"

    Rectangle {
      id: card
      anchors.fill: parent
      color: Theme.bg
      border.color: Theme.border
      border.width: 1
      opacity: root.open ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 150; easing.type: Theme.easingOut } }

      ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
          Layout.fillWidth: true
          Layout.topMargin: 16
          Layout.leftMargin: 18
          Layout.rightMargin: 18
          spacing: 8
          QIcon { name: "preferences-system"; size: 16; color: Theme.muted }
          Text {
            text: "SETTINGS"
            color: Theme.muted
            font.family: root.fontFamily
            font.pixelSize: 11
            font.letterSpacing: 2
          }
          Item { Layout.fillWidth: true }
        }

        RowLayout {
          Layout.fillWidth: true
          Layout.topMargin: 12
          Layout.leftMargin: 14
          Layout.rightMargin: 14
          spacing: 6
          Repeater {
            model: root.tabs
            delegate: Rectangle {
              required property var modelData
              required property int index
              Layout.fillWidth: true
              Layout.preferredHeight: 34
              color: root.activeTab === index ? Theme.fg
                   : (root.hoverTab === index ? Theme.bgAlt : "transparent")
              border.color: root.activeTab === index ? Theme.fg
                   : (root.hoverTab === index ? Theme.borderStrong : Theme.border)
              border.width: 1
              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hoverTab = index
                onExited: { if (root.hoverTab === index) root.hoverTab = -1 }
                onClicked: root.activeTab = index
              }
              RowLayout {
                anchors.centerIn: parent
                spacing: 7
                QIcon {
                  name: modelData.glyph
                  size: 16
                  color: root.activeTab === index ? Theme.bg : Theme.fg
                }
                Text {
                  text: modelData.name
                  color: root.activeTab === index ? Theme.bg : Theme.fg
                  font.family: root.fontFamily
                  font.pixelSize: 12
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.topMargin: 10
          height: 1
          color: Theme.border
        }

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true

          Flickable {
            anchors.fill: parent
            anchors.margins: 16
            contentHeight: contentCol.height
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
              id: contentCol
              anchors.left: parent.left
              anchors.right: parent.right
              spacing: 12

              ColumnLayout {
                visible: root.activeTab === 0
                Layout.fillWidth: true
                spacing: 10

                Text {
                  text: "APPEARANCE"
                  color: Theme.muted2
                  font.family: root.fontFamily
                  font.pixelSize: 9
                  font.letterSpacing: 2
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 56
                  color: root.selIdx === 0 ? Theme.fg
                       : (root.hoverIdx === 0 ? Theme.bgAlt : "transparent")
                  border.color: root.selIdx === 0 ? Theme.fg
                       : (root.hoverIdx === 0 ? Theme.borderStrong : Theme.border)
                  border.width: 1
                  MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.hoverIdx = 0
                    onExited: { if (root.hoverIdx === 0) root.hoverIdx = -1 }
                    onClicked: root.activate(0)
                  }
                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12
                    Item {
                      Layout.preferredWidth: 24
                      Layout.preferredHeight: 24
                      QIcon {
                        anchors.centerIn: parent
                        name: "wallpaper"
                        size: 22
                        color: root.selIdx === 0 ? Theme.bg : Theme.fg
                      }
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Layout.fillHeight: true
                      Layout.topMargin: 10
                      Layout.bottomMargin: 10
                      spacing: 3
                      Text {
                        text: "Wallpaper"
                        color: root.selIdx === 0 ? Theme.bg : Theme.fg
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                      }
                      Text {
                        text: "Set desktop wallpaper"
                        color: root.selIdx === 0 ? Theme.bgAlt : Theme.muted2
                        font.family: root.fontFamily
                        font.pixelSize: 10
                      }
                    }
                    Item {
                      Layout.preferredWidth: 20
                      Layout.preferredHeight: 20
                      QIcon {
                        anchors.centerIn: parent
                        name: "go-next"
                        size: 16
                        color: root.selIdx === 0 ? Theme.bg : Theme.muted
                      }
                    }
                  }
                }

                RowLayout {
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  Layout.topMargin: 4
                  spacing: 8
                  QIcon { name: "preferences-desktop-theme"; size: 16; color: Theme.muted }
                  Text {
                    text: "Icon theme"
                    color: Theme.fg
                    font.family: root.fontFamily
                    font.pixelSize: 12
                  }
                  Item { Layout.fillWidth: true }
                  Item {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    Rectangle {
                      anchors.fill: parent
                      color: root.hoverIdx === -3 ? Theme.fg : Theme.bgAlt
                      border.color: Theme.borderStrong
                      border.width: 1
                      Text { anchors.centerIn: parent; text: "<"; color: root.hoverIdx === -3 ? Theme.bg : Theme.fg; font.family: root.fontFamily; font.pixelSize: 12 }
                    }
                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onEntered: root.hoverIdx = -3
                      onExited: { if (root.hoverIdx === -3) root.hoverIdx = -1 }
                      onClicked: root.cycleIconTheme(-1)
                    }
                  }
                  Text {
                    text: Theme.iconTheme
                    color: Theme.fg
                    font.family: root.fontFamily
                    font.pixelSize: 11
                  }
                  Item {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    Rectangle {
                      anchors.fill: parent
                      color: root.hoverIdx === -4 ? Theme.fg : Theme.bgAlt
                      border.color: Theme.borderStrong
                      border.width: 1
                      Text { anchors.centerIn: parent; text: ">"; color: root.hoverIdx === -4 ? Theme.bg : Theme.fg; font.family: root.fontFamily; font.pixelSize: 12 }
                    }
                    MouseArea {
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onEntered: root.hoverIdx = -4
                      onExited: { if (root.hoverIdx === -4) root.hoverIdx = -1 }
                      onClicked: root.cycleIconTheme(1)
                    }
                  }
                }
              }

              ColumnLayout {
                visible: root.activeTab === 1
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                  model: root.audioModel
                  delegate: audioCardComp
                }
              }

              ColumnLayout {
                visible: root.activeTab === 2
                Layout.fillWidth: true
                spacing: 10

                Text {
                  text: "PROFILE"
                  color: Theme.muted2
                  font.family: root.fontFamily
                  font.pixelSize: 9
                  font.letterSpacing: 2
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 64
                  color: Theme.bgAlt
                  border.color: Theme.border
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12
                    Rectangle {
                      Layout.preferredWidth: 44
                      Layout.preferredHeight: 44
                      radius: 22
                      clip: true
                      color: Theme.bg
                      border.color: Theme.fg
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
                        color: Theme.muted3
                        font.family: root.fontFamily
                        font.pixelSize: 18
                      }
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Layout.fillHeight: true
                      Layout.topMargin: 12
                      Layout.bottomMargin: 12
                      spacing: 2
                      Text {
                        Layout.fillWidth: true
                        text: AvatarState.path !== "" ? AvatarState.path.split("/").pop() : "No profile picture"
                        color: Theme.fg
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideMiddle
                      }
                      Text {
                        text: "Shown on lockscreen"
                        color: Theme.muted2
                        font.family: root.fontFamily
                        font.pixelSize: 10
                      }
                    }
                    Rectangle {
                      Layout.preferredWidth: 64
                      Layout.preferredHeight: 28
                      color: root.hoverIdx === -6 ? Theme.fg : "transparent"
                      border.color: Theme.fg
                      border.width: 1
                      Text {
                        anchors.centerIn: parent
                        text: "Choose"
                        color: root.hoverIdx === -6 ? Theme.bg : Theme.fg
                        font.family: root.fontFamily
                        font.pixelSize: 11
                      }
                      MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoverIdx = -6
                        onExited: { if (root.hoverIdx === -6) root.hoverIdx = -1 }
                        onClicked: root.choose("avatar")
                      }
                    }
                    Rectangle {
                      Layout.preferredWidth: 56
                      Layout.preferredHeight: 28
                      visible: AvatarState.path !== ""
                      color: root.hoverIdx === -7 ? Theme.fg : "transparent"
                      border.color: Theme.fg
                      border.width: 1
                      Text {
                        anchors.centerIn: parent
                        text: "Clear"
                        color: root.hoverIdx === -7 ? Theme.bg : Theme.fg
                        font.family: root.fontFamily
                        font.pixelSize: 11
                      }
                      MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoverIdx = -7
                        onExited: { if (root.hoverIdx === -7) root.hoverIdx = -1 }
                        onClicked: AvatarState.clear()
                      }
                    }
                  }
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 50
                  color: Theme.bgAlt
                  border.color: Theme.border
                  border.width: 1
                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12
                    QIcon { name: "camera-photo"; size: 18; color: Theme.muted }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Layout.fillHeight: true
                      Layout.topMargin: 8
                      Layout.bottomMargin: 8
                      spacing: 2
                      Text {
                        text: "Avatar file"
                        color: Theme.fg
                        font.family: root.fontFamily
                        font.pixelSize: 12
                      }
                      Text {
                        text: AvatarState.path !== "" ? AvatarState.path : "No file selected"
                        color: Theme.muted2
                        font.family: root.fontFamily
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      Item {
        id: kbFocus
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
          if (event.key === Qt.Key_Escape) { root.requestClose(); event.accepted = true; return }
          if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
            root.activeTab = event.key === Qt.Key_Right
              ? (root.activeTab + 1) % root.tabs.length
              : (root.activeTab - 1 + root.tabs.length) % root.tabs.length
            root.selIdx = 0
            root.hoverIdx = -1
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

  Component {
    id: audioCardComp
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: modelData.header ? 20 : 54
      Rectangle {
        anchors.fill: parent
        visible: !modelData.header
        color: root.selIdx === index ? Theme.fg
             : (root.hoverIdx === index ? Theme.bgAlt : "transparent")
        border.color: root.selIdx === index ? Theme.fg
             : (modelData.def ? Theme.fg : (root.hoverIdx === index ? Theme.borderStrong : Theme.border))
        border.width: 1
        opacity: modelData.header ? 0 : 1
      }
      MouseArea {
        anchors.fill: parent
        visible: !modelData.header
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
        spacing: 12
        Item {
          Layout.preferredWidth: 24
          Layout.preferredHeight: 24
          QIcon {
            anchors.centerIn: parent
            name: modelData.type === "source" ? "mic" : "audio-volume-high"
            size: 20
            color: root.selIdx === index ? Theme.bg : Theme.fg
          }
        }
        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.topMargin: 8
          Layout.bottomMargin: 8
          spacing: 2
          Text {
            Layout.fillWidth: true
            text: modelData.desc || ""
            color: root.selIdx === index ? Theme.bg : Theme.fg
            font.family: root.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
          }
          Text {
            Layout.fillWidth: true
            text: modelData.name || ""
            color: root.selIdx === index ? Theme.bgAlt : Theme.muted2
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
        text: modelData.label || ""
        color: Theme.muted2
        font.family: root.fontFamily
        font.pixelSize: 9
        font.letterSpacing: 2
      }
    }
  }
}