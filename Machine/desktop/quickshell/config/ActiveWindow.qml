import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

RowLayout {
  id: root
  spacing: Theme.spacingS

  property string appId: ""
  property string appTitle: ""

  IconImage {
    id: appIcon
    Layout.preferredWidth: 16
    Layout.preferredHeight: 16
    Layout.alignment: Qt.AlignVCenter
    visible: root.appId !== ""
    implicitSize: 16
    source: {
      if (root.appId === "") return ""
      const de = DesktopEntries.heuristicLookup(root.appId)
      if (de && de.icon) return Quickshell.iconPath(de.icon, "application-x-executable")
      return Quickshell.iconPath(root.appId, "application-x-executable")
    }
  }

  Text {
    id: windowLabel
    text: root.appTitle
    color: "#ffffff"
    font.pixelSize: 12
    font.family: Theme.fontFamily
    elide: Text.ElideRight
    Layout.maximumWidth: 300
  }

  Process {
    running: true
    command: ["stdbuf", "-oL", "mmsg", "watch", "focusing-client"]
    stdout: SplitParser {
      onRead: data => {
        try {
          const d = JSON.parse(data)
          let t = String(d.title || "")
          if (t.length > 30) t = t.slice(0, 29) + "…"
          root.appTitle = t
          root.appId = String(d.appid || d.appId || "")
        } catch (e) {}
      }
    }
  }
}
