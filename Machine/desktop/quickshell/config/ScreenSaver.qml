pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root

    property bool shown: false

    visible: shown
    color: "#000000"
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "screensaver"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    function dismiss() { shown = false }

    onVisibleChanged: {
        if (visible) {
            timeProc.running = true
            dismissGrace.restart()
            ball.x = parent.width / 2
            ball.y = parent.height / 2
            vx = 300
            vy = 225
        }
    }

    property real vx: 300
    property real vy: 225
    readonly property int ballSize: 60

    Process {
        id: timeProc
        command: ["date", "+%H:%M"]
        stdout: SplitParser {
            onRead: data => timeText.text = data.trim()
        }
    }

    Timer {
        id: tick
        interval: 16
        running: root.shown
        repeat: true
        onTriggered: {
            var dt = 0.016
            var nx = ball.x + root.vx * dt
            var ny = ball.y + root.vy * dt
            var maxX = root.width - root.ballSize
            var maxY = root.height - root.ballSize
            if (nx <= 0) { nx = 0; root.vx = -root.vx; cornerHit() }
            else if (nx >= maxX) { nx = maxX; root.vx = -root.vx; cornerHit() }
            if (ny <= 0) { ny = 0; root.vy = -root.vy; cornerHit() }
            else if (ny >= maxY) { ny = maxY; root.vy = -root.vy; cornerHit() }
            ball.x = nx
            ball.y = ny
        }
    }

    function cornerHit() {
        timeProc.running = true
        cornerFlash.restart()
    }

    Timer {
        id: dismissGrace
        interval: 250
    }

    Timer {
        id: cornerFlash
        interval: 400
    }

    Rectangle {
        id: ball
        width: root.ballSize
        height: root.ballSize
        color: "transparent"
        border.color: cornerFlash.running ? "#ffffff" : "#888888"
        border.width: 1
    }

    Text {
        id: timeText
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        color: "#555555"
        font.family: Theme.fontFamily
        font.pixelSize: 14
        text: "--:--"
        opacity: cornerFlash.running ? 1.0 : 0.4
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: root.dismiss()
        onWheel: root.dismiss()
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: root.dismiss()
    }
}
