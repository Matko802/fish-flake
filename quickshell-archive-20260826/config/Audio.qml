pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Scope {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource

  readonly property bool sinkReady: sink && sink.ready && sink.audio && sink.audio.volumes.length > 0
  readonly property bool sourceReady: source && source.ready && source.audio && source.audio.volumes.length > 0

  readonly property int vol: sinkReady ? Math.round(sink.audio.volumes[0] * 100) : -1
  readonly property bool muted: sinkReady ? sink.audio.muted : false
  readonly property int micVol: sourceReady ? Math.round(source.audio.volumes[0] * 100) : -1
  readonly property bool micMuted: sourceReady ? source.audio.muted : false

  readonly property string icon: muted
    ? ""
    : (vol <= 30 ? "" : (vol < 65 ? "" : ""))
  readonly property string micIcon: micMuted ? "󰍭" : "󰍬"

  property int lastSound: 0

  function playVolumeSound() {
    const now = Date.now()
    if (now - lastSound < 250)
      return
    lastSound = now
    Quickshell.execDetached(["pw-play", "/run/current-system/sw/share/sounds/freedesktop/stereo/audio-volume-change.oga"])
  }

  function setVol(p) {
    if (!sinkReady)
      return
    const v = Math.max(0, Math.min(1, p / 100))
    sink.audio.volumes = sink.audio.volumes.map(() => v)
  }

  function toggleMute() {
    if (!sinkReady)
      return
    sink.audio.muted = !sink.audio.muted
  }

  function setMicVol(p) {
    if (!sourceReady)
      return
    const v = Math.max(0, Math.min(1, p / 100))
    source.audio.volumes = source.audio.volumes.map(() => v)
  }

  function toggleMicMute() {
    if (!sourceReady)
      return
    source.audio.muted = !source.audio.muted
  }

  PwObjectTracker {
    objects: [root.sink, root.source].filter(o => o)
  }
}
