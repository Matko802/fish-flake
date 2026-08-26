import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: osd

  property bool shown: false
  property bool armed: false

  anchors.bottom: true
  margins.bottom: 0
  exclusionMode: ExclusionMode.Ignore
  color: "transparent"
  WlrLayershell.namespace: "quickshell"
  WlrLayershell.layer: WlrLayer.Overlay
  implicitWidth: 380
  implicitHeight: 200
  visible: shown || bg.y > 96

  function show() {
    if (Audio.vol < 0)
      return
    osd.shown = true
    hideTimer.restart()
  }

  Timer {
    id: hideTimer
    interval: 1800
    onTriggered: osd.shown = false
  }

  Timer {
    id: armTimer
    interval: 1500
    running: true
    onTriggered: osd.armed = true
  }

  Connections {
    target: Audio
    function onVolChanged() {
      if (!osd.armed) return
      if (ControlState.open)
        return
      osd.show()
      if (ControlState.sliderDrags === 0)
        Audio.playVolumeSound()
    }
    function onMutedChanged() {
      if (!osd.armed || Audio.vol < 0) return
      if (ControlState.open)
        return
      osd.show()
      if (ControlState.sliderDrags === 0)
        Audio.playVolumeSound()
    }
  }

  Rectangle {
    id: bg
    width: parent.width
    height: 56
    y: osd.shown ? parent.height - 56 - 48 : parent.height
    Behavior on y { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    color: "#000000"
    border.color: "#ffffff"
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 12

      Text {
        text: Audio.icon
        color: "#ffffff"
        font.pixelSize: 18
        font.family: Theme.fontFamily
        Layout.preferredWidth: 24
        Layout.minimumWidth: 24
        Layout.maximumWidth: 24
        horizontalAlignment: Text.AlignHCenter
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Audio.toggleMute()
        }
      }

      CSlider {
        id: osdSlider
        Layout.fillWidth: true
        value: Audio.vol < 0 ? 0 : Audio.vol / 100
        onUserSet: v => {
          Audio.setVol(v * 100)
          hideTimer.restart()
        }
      }

      Text {
        text: Math.round(osdSlider.shown * 100) + "%"
        color: "#ffffff"
        font.pixelSize: 12
        Layout.preferredWidth: 40
        Layout.minimumWidth: 40
        Layout.maximumWidth: 40
        horizontalAlignment: Text.AlignRight
      }
    }
  }
}
