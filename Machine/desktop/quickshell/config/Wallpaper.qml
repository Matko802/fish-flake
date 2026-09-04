import QtQuick
import Quickshell
import Quickshell.Wayland

// Background-layer window that renders the current wallpaper with a
// crossfade whenever WallpaperState.path changes.
PanelWindow {
  id: window

  anchors.top: true
  anchors.bottom: true
  anchors.left: true
  anchors.right: true
  exclusionMode: ExclusionMode.Ignore
  color: "#000000"
  WlrLayershell.namespace: "quickshell-wallpaper"
  WlrLayershell.layer: WlrLayer.Background

  Item {
    id: bg

    anchors.fill: parent

    property bool frontIsA: true
    property var pending: null
    property int retryCount: 0
    readonly property int maxRetries: 4

    function fileUrl(path) {
      return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }

    function checkReady(img) {
      if (bg.pending !== img || img.status !== Image.Ready)
        return
      bg.pending = null
      bg.retryCount = 0
      bg.frontIsA = img === imgA
      imgA.opacity = img === imgA ? 1 : 0
      imgB.opacity = img === imgB ? 1 : 0
    }

    // A failed load must never take down the currently visible wallpaper:
    // clear the pending request and retry, in case the file was momentarily
    // unavailable (late-mounted drive, still being copied, etc).
    function checkError(img) {
      if (bg.pending !== img)
        return
      bg.pending = null
      if (bg.retryCount < bg.maxRetries) {
        bg.retryCount += 1
        retryTimer.img = img
        retryTimer.url = img.source
        retryTimer.restart()
      }
    }

    function onImageStatus(img) {
      if (img.status === Image.Ready)
        bg.checkReady(img)
      else if (img.status === Image.Error)
        bg.checkError(img)
    }

    Timer {
      id: retryTimer

      interval: 1500
      property var img: null
      property string url: ""

      onTriggered: {
        // A newer pick superseded this request while it was failing.
        if (bg.pending !== null)
          return
        if (retryTimer.img !== img || img.source !== url)
          return
        img.source = ""
        img.source = url
        bg.pending = img
        bg.checkReady(img)
      }
    }

    function show(path) {
      if (path === "")
        return
      const back = bg.frontIsA ? imgB : imgA
      const front = bg.frontIsA ? imgA : imgB
      if (front.source === bg.fileUrl(path))
        return
      back.source = bg.fileUrl(path)
      bg.pending = back
      bg.checkReady(back)
    }

    Connections {
      target: WallpaperState
      function onPathChanged() {
        bg.show(WallpaperState.path)
      }
    }

    Component.onCompleted: bg.show(WallpaperState.path)

    // Decode at a sane cap so 6K/8K wallpapers don't take seconds to load
    // (long black gap during the initial crossfade).
    Image {
      id: imgA
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize: Qt.size(3840, 2160)
      opacity: 0
      Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
      onStatusChanged: bg.onImageStatus(imgA)
    }

    Image {
      id: imgB
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize: Qt.size(3840, 2160)
      opacity: 0
      Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
      onStatusChanged: bg.onImageStatus(imgB)
    }
  }
}
