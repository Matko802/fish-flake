import QtQuick

Rectangle {
  id: root

  property real value: 0
  signal userSet(real v)

  implicitWidth: 120
  implicitHeight: 16
  color: "transparent"

  readonly property real clamped: Math.max(0, Math.min(1, value))
  readonly property real pad: 8
  property bool dragging: false
  property real dragValue: 0
  readonly property real shown: dragging ? Math.max(0, Math.min(1, dragValue)) : clamped

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 6
    radius: 0
    color: "#1a1a1a"
    border.color: "#333333"
    border.width: 1

    readonly property real center: Math.round(9 + (width - 18) * root.shown)

    // Filled portion
    Rectangle {
      width: Math.min(parent.width, parent.center + 7)
      height: parent.height
      radius: 0
      color: "#ffffff"
      border.color: "#ffffff"
      border.width: 1
    }

    // Handle — big white cube, 14px, 2px inset like CToggle
    Rectangle {
      x: parent.center - 7
      anchors.verticalCenter: parent.verticalCenter
      width: 14
      height: 14
      radius: 0
      color: "#ffffff"
      border.color: "#ffffff"
      border.width: 1
    }
  }

  MouseArea {
    anchors.fill: parent
    anchors.margins: -root.pad
    cursorShape: Qt.PointingHandCursor
    preventStealing: true

    function apply(mouse) {
      // MouseArea extends `pad` past both edges; map back into track space.
      const v = Math.max(0, Math.min(1, (mouse.x - root.pad) / root.width))
      root.dragValue = v
      root.userSet(v)
    }

    onPressed: mouse => {
      root.dragging = true
      ControlState.sliderDrags++
      apply(mouse)
    }
    onPositionChanged: mouse => {
      if (pressed)
        apply(mouse)
    }
    onReleased: {
      root.dragging = false
      if (ControlState.sliderDrags > 0)
        ControlState.sliderDrags--
    }
    onCanceled: {
      root.dragging = false
      if (ControlState.sliderDrags > 0)
        ControlState.sliderDrags--
    }
    onWheel: wheel => root.userSet(root.shown + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
  }
}
