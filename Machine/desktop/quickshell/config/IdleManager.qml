pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    property bool enabled: true
    property int lockTimeout: 300
    property int suspendTimeout: 600
    property int _idleSeconds: 0
    property bool mediaPlaying: {
        const ps = Mpris.players ? Mpris.players.values : []
        for (let i = 0; i < ps.length; i++) {
            if (ps[i] && ps[i].isPlaying) return true
        }
        return false
    }
    // True when any PipeWire output stream is actively producing audio
    // (state running and not corked). Catches players with no MPRIS support
    // (e.g. mpv without the mpris script, sandboxed players).
    property bool audioActive: false
    property bool gameMode: false
    // "Coffee" stay-awake toggle (set from ClockMenu). While true the session
    // is treated as permanently active, so it never auto-locks or suspends.
    property bool stayAwake: false

    // Guards prevent re-firing in a loop after the action already happened.
    // They only re-arm once we observe a genuine input event or media playback.
    property bool lockArmed: true
    property bool suspendArmed: true

    function reset() {
        _idleSeconds = 0
        lockArmed = true
        suspendArmed = true
    }

    function toggle() {
        enabled = !enabled
    }

    function markActive() {
        root._idleSeconds = 0
        root.lockArmed = true
        root.suspendArmed = true
    }

    Connections {
        target: LockState
        function onLockedChanged() {
            if (LockState.locked) {
                root._idleSeconds = 0
                root.lockArmed = true
            }
        }
    }

    // Real input detection: the compositor streams an event for every input
    // device activity. Each event resets the idle clock. logind's IdleHint
    // does NOT work on Wayland (it never learns about input), so this is the
    // reliable source.
    Process {
        id: activityWatch
        running: root.enabled
        command: ["mmsg", "watch", "all-devices"]
        stdout: SplitParser {
            onRead: _ => root.markActive()
        }
    }

    // Media playback should suppress idle (don't blank/lock/suspend while a
    // video or music is playing). Detect via MPRIS (mediaPlaying) and active
    // PipeWire audio output (audioActive, catches non-MPRIS players).
    Timer {
        interval: 3000
        running: root.enabled
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            gameCheck.running = true
            audioCheck.running = true
        }
    }

    // A game running under gamemode should also suppress idle. Poll gamemode's
    // active state; if a game has requested gamemode, treat it as activity.
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
        }
    }

    Timer {
        interval: 1000
        running: root.enabled
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            if (root.mediaPlaying || root.audioActive || root.gameMode || root.stayAwake) {
                root.markActive()
                return
            }
            root._idleSeconds += 1
            const locked = LockState.locked
            if (!locked && root.lockArmed && root._idleSeconds >= root.lockTimeout) {
                LockState.locked = true
                root.lockArmed = false
            }
            if (root.suspendArmed && root._idleSeconds >= root.suspendTimeout) {
                suspendProc.running = true
                root.suspendArmed = false
            }
        }
    }

    Process {
        id: suspendProc
        command: ["systemctl", "suspend"]
    }
}
