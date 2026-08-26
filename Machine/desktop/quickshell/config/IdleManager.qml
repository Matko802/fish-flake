pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool enabled: true
    property int screensaverTimeout: 150
    property int lockTimeout: 300
    property int suspendTimeout: 600
    property int _idleSeconds: 0

    function reset() {
        _idleSeconds = 0
    }

    function toggle() {
        enabled = !enabled
    }

    Connections {
        target: ScreenSaver
        function onShownChanged() {
            if (!ScreenSaver.shown)
                root._idleSeconds = 0
        }
    }

    Timer {
        interval: 1000
        running: root.enabled
        repeat: true
        onTriggered: {
            if (!LockState.locked && !activityCheck.running)
                activityCheck.running = true
        }
    }

    Process {
        id: activityCheck
        property string result: ""
        command: ["bash", "-c", "if [ ! -f /tmp/.qs_idle_marker ]; then touch /tmp/.qs_idle_marker; echo idle; exit 0; fi; keyboard_devs=\"\"; for dev in /dev/input/event*; do base=$(basename \"$dev\"); name=$(cat \"/sys/class/input/$base/device/name\" 2>/dev/null); if echo \"$name\" | grep -qi 'kbd\\|keyboard'; then keyboard_devs=\"$keyboard_devs $dev\"; fi; done; if [ -z \"$keyboard_devs\" ]; then echo idle; exit 0; fi; if [ -n \"$(find $keyboard_devs -newer /tmp/.qs_idle_marker 2>/dev/null)\" ]; then echo active; else echo idle; fi; touch /tmp/.qs_idle_marker"]
        stdout: SplitParser {
            onRead: data => activityCheck.result = data.trim()
        }
        onExited: {
            if (activityCheck.result === "active") {
                root._idleSeconds = 0
                ScreenSaver.dismiss()
            } else {
                root._idleSeconds++
                if (!LockState.locked && root._idleSeconds >= root.screensaverTimeout)
                    ScreenSaver.shown = true
                if (!LockState.locked && root._idleSeconds >= root.lockTimeout)
                    LockState.locked = true
                if (root._idleSeconds >= root.suspendTimeout)
                    suspendProc.running = true
            }
            activityCheck.result = ""
        }
    }

    Process {
        id: suspendProc
        command: ["systemctl", "suspend"]
    }
}
