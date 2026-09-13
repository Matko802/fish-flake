pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Power
import Quickshell.Services.Mpris
import Quickshell.Wayland

Item {
    id: root

    property bool enabled: true

    property int lockTimeout: 300
    property int screenOffDelay: 15
    property int suspendTimeout: 600

    property int _idleSeconds: 0
    property bool screenIsOff: false

    property bool lockStageArmed: true
    property bool screenOffStageArmed: true
    property bool suspendStageArmed: true

    property bool mediaPlaying: {
        const ps = Mpris.players ? Mpris.players.values : []
        for (let i = 0; i < ps.length; i++) {
            if (ps[i] && ps[i].isPlaying) return true
        }
        return false
    }
    property bool audioActive: false
    property bool gameMode: false
    property bool stayAwake: false
    readonly property bool _inhibited: mediaPlaying || audioActive || gameMode || stayAwake

    function _setScreen(off) {
        if (off === root.screenIsOff)
            return
        root.screenIsOff = off
        outputPower.setAllPower(!off)
    }

    function markActive() {
        root._idleSeconds = 0
        root.lockStageArmed = true
        root.screenOffStageArmed = true
        root.suspendStageArmed = true
        root._setScreen(false)
    }

    function toggle() {
        enabled = !enabled
    }

    IdleMonitor {
        id: nativeIdle
        enabled: root.enabled
        timeout: 1
        respectInhibitors: false
        onIsIdleChanged: if (!isIdle) root.markActive()
    }

    Process {
        id: activityWatch
        running: root.enabled
        command: ["sh", "-c", "command -v mmsg >/dev/null 2>&1 && exec stdbuf -oL mmsg watch all-devices || sleep 999999"]
        stdout: SplitParser {
            onRead: _ => root.markActive()
        }
    }

    Connections {
        target: LockState
        function onLockedChanged() {
            if (LockState.locked) {
                root._idleSeconds = 0
                root.lockStageArmed = true
                root.screenOffStageArmed = true
            } else {
                root._setScreen(false)
                root.screenOffStageArmed = true
            }
        }
    }

    Timer {
        interval: 3000
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            gameCheck.running = true
            audioCheck.running = true
            if (root.mediaPlaying)
                root.markActive()
        }
    }

    Process {
        id: gameCheck
        command: ["sh", "-c", "command -v gamemode_query >/dev/null 2>&1 && gamemode_query 2>/dev/null | grep -qi 'is active'"]
        onExited: (exitCode) => {
            const active = exitCode === 0
            root.gameMode = active
            if (active)
                root.markActive()
        }
    }

    Process {
        id: audioCheck
        command: ["sh", "-c", "pw-dump 2>/dev/null | awk '/^  \\{$/ { b=\"\"; f=1; next } /^  \\},?$/ { if (f && b ~ /\"media.class\"[[:space:]]*:[[:space:]]*\"Stream\\/Output\\/Audio\"/ && b ~ /\"state\"[[:space:]]*:[[:space:]]*\"running\"/ && b !~ /\"pulse.corked\"[[:space:]]*:[[:space:]]*true/) { print \"P\"; exit } f=0; next } f { b = b \"\\n\" $0 }' | grep -q P"]
        onExited: (exitCode) => {
            root.audioActive = (exitCode === 0)
            if (exitCode === 0)
                root.markActive()
        }
    }

    Timer {
        id: idleClock
        interval: 1000
        running: root.enabled
        repeat: true
        onTriggered: {
            if (root._inhibited) {
                root.markActive()
                return
            }
            root._idleSeconds += 1
            const locked = LockState.locked
            if (!locked && root.lockStageArmed && root._idleSeconds >= root.lockTimeout) {
                LockState.locked = true
                root.lockStageArmed = false
            }
            if (locked && root.screenOffStageArmed && root._idleSeconds >= root.screenOffDelay) {
                root._setScreen(true)
                root.screenOffStageArmed = false
            }
            if (root.suspendStageArmed && root._idleSeconds >= root.suspendTimeout) {
                suspendProc.running = true
                root.suspendStageArmed = false
            }
        }
    }

    OutputPower {
        id: outputPower
    }

    Process { id: suspendProc; command: ["systemctl", "suspend"] }
}
