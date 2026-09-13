import QtQuick
import Quickshell
import Quickshell.Wayland

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

    function checkError(img) {
      if (bg.pending !== img)
        return
      bg.pending = null
      if (bg.retryCount >= bg.maxRetries)
        return
      bg.retryCount += 1
      retryTimer.img = img
      retryTimer.url = String(img.source)
      retryTimer.interval = Math.min(15000, 1500 * Math.pow(2, bg.retryCount - 1))
      retryTimer.restart()
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
        if (bg.pending !== null)
          return
        const target = retryTimer.img
        if (!target || String(target.source) !== retryTimer.url)
          return
        target.source = ""
        target.source = retryTimer.url
        bg.pending = target
        bg.checkReady(target)
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
