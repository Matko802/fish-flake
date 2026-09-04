pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Power
import Quickshell.Services.Mpris
import Quickshell.Wayland

// Idle stage manager.
//
// On niri (now default) native Quickshell.IdleMonitor works via ext-idle-notify-v1.
// On mango (archived) only wlr_idle_notifier_v1 exists, so we kept mmsg watch as
// fallback. Both sources feed the same 1s clock that sequences lock →
// screen-off → suspend. Screen power uses the bundled OutputPower plugin
// (wlr-output-power-management-v1, no wlopm binary).
Item {
    id: root

    property bool enabled: true

    // ---- stage timeouts (seconds) ----
    property int lockTimeout: 300
    property int screenOffDelay: 15
    property int suspendTimeout: 600

    // ---- idle state ----
    property int _idleSeconds: 0
    property bool screenIsOff: false

    // Guards stop a stage re-firing in a loop once acted on. Each re-arms only
    // when real activity is observed (see markActive).
    property bool lockStageArmed: true
    property bool screenOffStageArmed: true
    property bool suspendStageArmed: true

    // Media/GPU "don't go idle" flags. Any one being true keeps the session
    // marked active so it never locks, blanks, or suspends.
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
    readonly property bool _inhibited: mediaPlaying || audioActive || gameMode || stayAwake

    function _setScreen(off) {
        if (off === root.screenIsOff)
            return
        root.screenIsOff = off
        outputPower.setAllPower(!off)
    }

    // Any genuine activity (input event, media/GPU playback, unlocking) resets
    // the idle clock, re-arms every stage, and wakes a blanked screen.
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

    // Native idle watcher — works on niri (ext-idle-notify-v1), no-op on mango.
    IdleMonitor {
        id: nativeIdle
        enabled: root.enabled
        timeout: 1
        respectInhibitors: false
        onIsIdleChanged: if (!isIdle) root.markActive()
    }

    // Mango fallback: mmsg streams an event per input device. Kept for
    // archived mango, harmless on niri (binary not found → process just exits).
    Process {
        id: activityWatch
        running: root.enabled
        command: ["mmsg", "watch", "all-devices"]
        stdout: SplitParser {
            onRead: _ => root.markActive()
        }
    }

    // Propagate locking through LockState and keep the locked screen awake
    // during the grace period, then allow screen-off afterwards.
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

    // Media playback should suppress idle (don't blank/lock/suspend while a
    // video or music is playing). Poll MPRIS (mediaPlaying) and live PipeWire
    // audio output (audioActive, catches non-MPRIS players).
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
            if (exitCode === 0)
                root.markActive()
        }
    }

    // The idle clock: advances one second per tick unless the session is
    // inhibited. Fires each stage exactly once in order when its timeout hits.
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
