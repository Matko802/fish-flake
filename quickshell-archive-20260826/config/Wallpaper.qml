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

    function fileUrl(path) {
      return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }

    function checkReady(img) {
      if (bg.pending !== img || img.status !== Image.Ready)
        return
      bg.pending = null
      bg.frontIsA = img === imgA
      imgA.opacity = img === imgA ? 1 : 0
      imgB.opacity = img === imgB ? 1 : 0
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

    Image {
      id: imgA
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      opacity: 0
      Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
      onStatusChanged: bg.checkReady(imgA)
    }

    Image {
      id: imgB
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      opacity: 0
      Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
      onStatusChanged: bg.checkReady(imgB)
    }
  }
}
