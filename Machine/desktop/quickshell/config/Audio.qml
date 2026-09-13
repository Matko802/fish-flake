pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Scope {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource

  readonly property bool sinkReady: sink && sink.ready && sink.audio && sink.audio.volumes.length > 0
  readonly property bool sourceReady: source && source.ready && source.audio && source.audio.volumes.length > 0

  property int _vol: -1
  property bool _muted: false
  property int _micVol: -1
  property bool _micMuted: false

  readonly property int vol: sinkReady ? Math.round(sink.audio.volumes[0] * 100) : (root._vol >= 0 ? root._vol : -1)
  readonly property bool muted: sinkReady ? sink.audio.muted : root._muted
  readonly property int micVol: sourceReady ? Math.round(source.audio.volumes[0] * 100) : (root._micVol >= 0 ? root._micVol : -1)
  readonly property bool micMuted: sourceReady ? source.audio.muted : root._micMuted

  readonly property string icon: muted
    ? "audio-volume-muted"
    : (vol <= 30 ? "audio-volume-low" : (vol < 65 ? "audio-volume-medium" : "audio-volume-high"))
  readonly property string micIcon: micMuted ? "mic-muted" : "mic"

  property int lastSound: 0
  property int _volIdx: 0

  function playVolumeSound() {
    const now = Date.now()
    if (now - lastSound < 150)
      return
    lastSound = now
    Quickshell.execDetached(["pw-play", "/run/current-system/sw/share/sounds/freedesktop/stereo/audio-volume-change.oga"])
  }

  Process {
    id: volInit
    running: true
    command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null; wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null"]
    stdout: SplitParser {
      onRead: line => {
        const s = String(line)
        const m = s.match(/Volume:\s*([0-9.]+)(?:\s*\[MUTED\])?/)
        if (!m)
          return
        const val = Math.round(parseFloat(m[1]) * 100)
        const muted = /\[MUTED\]/.test(s)
        if (root._volIdx === 0) {
          root._vol = val
          root._muted = muted
        } else {
          root._micVol = val
          root._micMuted = muted
        }
        root._volIdx++
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      if (!root.sinkReady && !volInit.running) {
        root._volIdx = 0
        volInit.running = true
      }
    }
  }

  function setVol(p) {
    const v = Math.max(0, Math.min(1, p / 100))
    if (sinkReady) {
      sink.audio.volumes = sink.audio.volumes.map(() => v)
    } else {
      root._vol = Math.round(v * 100)
      Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(v * 100) + "%"])
    }
  }

  function toggleMute() {
    if (sinkReady) {
      sink.audio.muted = !sink.audio.muted
    } else {
      root._muted = !root._muted
      Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", root._muted ? "1" : "0"])
    }
  }

  function setMicVol(p) {
    const v = Math.max(0, Math.min(1, p / 100))
    if (sourceReady) {
      source.audio.volumes = source.audio.volumes.map(() => v)
    } else {
      root._micVol = Math.round(v * 100)
      Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", Math.round(v * 100) + "%"])
    }
  }

  function toggleMicMute() {
    if (sourceReady) {
      source.audio.muted = !source.audio.muted
    } else {
      root._micMuted = !root._micMuted
      Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", root._micMuted ? "1" : "0"])
    }
  }

  function setDefaultSink(id) {
    Quickshell.execDetached(["wpctl", "set-default", String(id)])
  }

  function setDefaultSource(id) {
    Quickshell.execDetached(["wpctl", "set-default", String(id)])
  }

  PwObjectTracker {
    objects: [root.sink, root.source].filter(o => o)
  }
}
